# main.py
# FastAPI REST API (Airbnb lab project)

from datetime import date
from typing import Optional

from fastapi import FastAPI, HTTPException, Query, Depends, Response
from fastapi.middleware.cors import CORSMiddleware

from sqlalchemy.orm import Session
from sqlalchemy import func, asc, desc, text
from sqlalchemy.exc import IntegrityError

from database import SessionLocal, engine
from models import User, Listing, Booking, Base
from schemas import (
    UserCreate, UserUpdate, UserResponse,
    ListingCreate, ListingUpdate, ListingResponse,
    BookingCreate, BookingUpdate, BookingResponse,
    HostStatsResponse
)

# =========================================================
# APP
# =========================================================

app = FastAPI(title="Airbnb API", version="3.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# =========================================================
# DB
# =========================================================

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# =========================================================
# USERS
# =========================================================

@app.post("/users", response_model=UserResponse, status_code=201)
def create_user(user: UserCreate, db: Session = Depends(get_db)):

    db_user = User(**user.model_dump())
    db.add(db_user)

    try:
        db.commit()
        db.refresh(db_user)
        return db_user

    except IntegrityError as e:
        db.rollback()
        raise HTTPException(400, f"User error: {str(e)}")


@app.get("/users", response_model=list[UserResponse])
def get_users(
    page: int = 1,
    limit: int = 10,
    sort: str = "user_id",
    order: str = "asc",
    db: Session = Depends(get_db)
):

    allowed = {
        "user_id": User.user_id,
        "email": User.email,
        "role": User.role,
    }

    if sort not in allowed:
        raise HTTPException(400, "Invalid sort field")

    if order not in ("asc", "desc"):
        raise HTTPException(400, "Invalid order")

    query = db.query(User)

    sort_col = allowed[sort]
    query = query.order_by(
        asc(sort_col) if order == "asc" else desc(sort_col)
    )

    return query.offset((page - 1) * limit).limit(limit).all()


@app.delete("/users/{user_id}", status_code=204)
def delete_user(user_id: int, db: Session = Depends(get_db)):

    user = db.query(User).filter(User.user_id == user_id).first()

    if not user:
        raise HTTPException(404, "User not found")

    db.delete(user)
    db.commit()
    return Response(status_code=204)

# =========================================================
# LISTINGS
# =========================================================

@app.post("/listings", response_model=ListingResponse, status_code=201)
def create_listing(listing: ListingCreate, db: Session = Depends(get_db)):

    host = db.query(User).filter(User.user_id == listing.host_id).first()

    if not host:
        raise HTTPException(404, "Host not found")

    db_listing = Listing(**listing.model_dump())
    db.add(db_listing)

    try:
        db.commit()
        db.refresh(db_listing)
        return db_listing

    except IntegrityError as e:
        db.rollback()
        raise HTTPException(400, str(e))


@app.get("/listings", response_model=list[ListingResponse])
def get_listings(
    city: Optional[str] = None,
    min_price: Optional[float] = None,
    max_price: Optional[float] = None,
    db: Session = Depends(get_db)
):

    query = db.query(Listing)

    if city:
        query = query.filter(Listing.city == city)

    if min_price is not None:
        query = query.filter(Listing.price_per_night >= min_price)

    if max_price is not None:
        query = query.filter(Listing.price_per_night <= max_price)

    return query.all()


@app.delete("/listings/{listing_id}", status_code=204)
def delete_listing(listing_id: int, db: Session = Depends(get_db)):

    listing = db.query(Listing).filter(Listing.listing_id == listing_id).first()

    if not listing:
        raise HTTPException(404, "Listing not found")

    db.delete(listing)
    db.commit()

    return Response(status_code=204)

# =========================================================
# BOOKINGS (САМОЕ ВАЖНОЕ)
# =========================================================

def check_overlap(db, listing_id: int, start_date: date, end_date: date):

    return db.query(Booking).filter(
        Booking.listing_id == listing_id,
        Booking.status != "cancelled",
        start_date < Booking.end_date,
        end_date > Booking.start_date
    ).first()


@app.post("/bookings", response_model=BookingResponse, status_code=201)
def create_booking(booking: BookingCreate, db: Session = Depends(get_db)):

    listing = db.query(Listing).filter(
        Listing.listing_id == booking.listing_id
    ).first()

    if not listing:
        raise HTTPException(404, "Listing not found")

    guest = db.query(User).filter(
        User.user_id == booking.guest_id
    ).first()

    if not guest:
        raise HTTPException(404, "Guest not found")

    # нельзя бронировать свой объект
    if listing.host_id == booking.guest_id:
        raise HTTPException(400, "Cannot book own listing")

    # проверка гостей
    if booking.guest_count > listing.max_guests:
        raise HTTPException(400, "Too many guests")

    # даты
    if booking.end_date <= booking.start_date:
        raise HTTPException(400, "Invalid date range")

    # пересечение
    overlap = check_overlap(
        db,
        booking.listing_id,
        booking.start_date,
        booking.end_date
    )

    if overlap:
        raise HTTPException(400, "Dates already booked")

    db_booking = Booking(**booking.model_dump())
    db.add(db_booking)

    try:
        db.commit()
        db.refresh(db_booking)
        return db_booking

    except IntegrityError as e:
        db.rollback()
        raise HTTPException(400, str(e))


@app.put("/bookings/{booking_id}", response_model=BookingResponse)
def update_booking(booking_id: int, booking: BookingUpdate, db: Session = Depends(get_db)):

    db_booking = db.query(Booking).filter(
        Booking.booking_id == booking_id
    ).first()

    if not db_booking:
        raise HTTPException(404, "Booking not found")

    for k, v in booking.model_dump(exclude_unset=True).items():
        setattr(db_booking, k, v)

    db.commit()
    db.refresh(db_booking)

    return db_booking


@app.delete("/bookings/{booking_id}", status_code=204)
def delete_booking(booking_id: int, db: Session = Depends(get_db)):

    booking = db.query(Booking).filter(
        Booking.booking_id == booking_id
    ).first()

    if not booking:
        raise HTTPException(404, "Booking not found")

    db.delete(booking)
    db.commit()

    return Response(status_code=204)

# =========================================================
# REPORTS
# =========================================================

@app.get("/reports/bookings-by-status")
def bookings_by_status(db: Session = Depends(get_db)):

    result = db.query(
        Booking.status,
        func.count(Booking.booking_id)
    ).group_by(Booking.status).all()

    return [{"status": s, "count": c} for s, c in result]


@app.get("/reports/listings-by-city")
def listings_by_city(db: Session = Depends(get_db)):

    result = db.query(
        Listing.city,
        func.count(Listing.listing_id)
    ).group_by(Listing.city).all()

    return [{"city": c, "count": n} for c, n in result]

# =========================================================
# VIEWS
# =========================================================

@app.get("/views/active-listings")
def active_listings(db: Session = Depends(get_db)):

    result = db.execute(text("SELECT * FROM active_listings_with_rating"))
    return [dict(r) for r in result.mappings()]

# =========================================================
# PROCEDURE
# =========================================================

@app.post("/bookings/procedure")
def create_booking_proc(
    listing_id: int,
    guest_id: int,
    start_date: date,
    end_date: date,
    guest_count: int,
    db: Session = Depends(get_db)
):

    db.execute(
        text("""
            CALL create_booking(
                :listing_id,
                :guest_id,
                :start_date,
                :end_date,
                :guest_count,
                NULL,
                NULL
            )
        """),
        {
            "listing_id": listing_id,
            "guest_id": guest_id,
            "start_date": start_date,
            "end_date": end_date,
            "guest_count": guest_count,
        }
    )

    db.commit()

    return {"message": "Created via procedure"}