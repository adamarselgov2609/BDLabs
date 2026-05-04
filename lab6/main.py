# main.py
# FastAPI приложение — REST API для базы данных Airbnb

from fastapi import FastAPI, HTTPException, Query, Depends
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from sqlalchemy import func, desc, asc
from typing import Optional
from database import SessionLocal, engine
from models import Base, User, Listing, Booking, Review, Payment
from schemas import UserCreate, UserUpdate, UserResponse, ListingCreate, ListingUpdate, ListingResponse, BookingCreate, BookingUpdate, BookingResponse, HostStatsResponse

app = FastAPI(title="Airbnb API", version="1.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)
# Зависимость — сессия БД
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


# ============================================
# USERS (CRUD + фильтрация, сортировка, пагинация)
# ============================================

@app.get("/users", response_model=list[UserResponse])
def get_users(
    page: int = Query(1, ge=1),
    limit: int = Query(10, ge=1, le=100),
    sort: str = "user_id",
    order: str = "asc",
    role: Optional[str] = None,
    db: Session = Depends(get_db)
):
    query = db.query(User)
    if role:
        query = query.filter(User.role == role)
    sort_column = getattr(User, sort, User.user_id)
    query = query.order_by(asc(sort_column) if order == "asc" else desc(sort_column))
    offset = (page - 1) * limit
    return query.offset(offset).limit(limit).all()


@app.get("/users/{user_id}", response_model=UserResponse)
def get_user(user_id: int, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.user_id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="Пользователь не найден")
    return user


@app.post("/users", response_model=UserResponse, status_code=201)
def create_user(user: UserCreate, db: Session = Depends(get_db)):
    db_user = User(**user.model_dump())
    db.add(db_user)
    try:
        db.commit()
        db.refresh(db_user)
        return db_user
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=400, detail=f"Ошибка: {str(e)}")


@app.put("/users/{user_id}", response_model=UserResponse)
def update_user(user_id: int, user: UserUpdate, db: Session = Depends(get_db)):
    db_user = db.query(User).filter(User.user_id == user_id).first()
    if not db_user:
        raise HTTPException(status_code=404, detail="Пользователь не найден")
    for key, value in user.model_dump(exclude_unset=True).items():
        setattr(db_user, key, value)
    db.commit()
    db.refresh(db_user)
    return db_user


@app.delete("/users/{user_id}", status_code=204)
def delete_user(user_id: int, db: Session = Depends(get_db)):
    db_user = db.query(User).filter(User.user_id == user_id).first()
    if not db_user:
        raise HTTPException(status_code=404, detail="Пользователь не найден")
    db.delete(db_user)
    db.commit()


# ============================================
# LISTINGS (CRUD + фильтрация, сортировка, пагинация)
# ============================================

@app.get("/listings", response_model=list[ListingResponse])
def get_listings(
    page: int = Query(1, ge=1),
    limit: int = Query(10, ge=1, le=100),
    sort: str = "listing_id",
    order: str = "asc",
    city: Optional[str] = None,
    property_type: Optional[str] = None,
    min_price: Optional[float] = None,
    max_price: Optional[float] = None,
    is_active: Optional[bool] = None,
    db: Session = Depends(get_db)
):
    query = db.query(Listing)
    if city:
        query = query.filter(Listing.city == city)
    if property_type:
        query = query.filter(Listing.property_type == property_type)
    if min_price is not None:
        query = query.filter(Listing.price_per_night >= min_price)
    if max_price is not None:
        query = query.filter(Listing.price_per_night <= max_price)
    if is_active is not None:
        query = query.filter(Listing.is_active == is_active)
    sort_column = getattr(Listing, sort, Listing.listing_id)
    query = query.order_by(asc(sort_column) if order == "asc" else desc(sort_column))
    offset = (page - 1) * limit
    return query.offset(offset).limit(limit).all()


@app.get("/listings/{listing_id}", response_model=ListingResponse)
def get_listing(listing_id: int, db: Session = Depends(get_db)):
    listing = db.query(Listing).filter(Listing.listing_id == listing_id).first()
    if not listing:
        raise HTTPException(status_code=404, detail="Объявление не найдено")
    return listing


@app.post("/listings", response_model=ListingResponse, status_code=201)
def create_listing(listing: ListingCreate, db: Session = Depends(get_db)):
    db_listing = Listing(**listing.model_dump())
    db.add(db_listing)
    try:
        db.commit()
        db.refresh(db_listing)
        return db_listing
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=400, detail=f"Ошибка: {str(e)}")


@app.put("/listings/{listing_id}", response_model=ListingResponse)
def update_listing(listing_id: int, listing: ListingUpdate, db: Session = Depends(get_db)):
    db_listing = db.query(Listing).filter(Listing.listing_id == listing_id).first()
    if not db_listing:
        raise HTTPException(status_code=404, detail="Объявление не найдено")
    for key, value in listing.model_dump(exclude_unset=True).items():
        setattr(db_listing, key, value)
    db.commit()
    db.refresh(db_listing)
    return db_listing


@app.delete("/listings/{listing_id}", status_code=204)
def delete_listing(listing_id: int, db: Session = Depends(get_db)):
    db_listing = db.query(Listing).filter(Listing.listing_id == listing_id).first()
    if not db_listing:
        raise HTTPException(status_code=404, detail="Объявление не найдено")
    db.delete(db_listing)
    db.commit()


# ============================================
# BOOKINGS (CRUD)
# ============================================

@app.get("/bookings", response_model=list[BookingResponse])
def get_bookings(
    page: int = Query(1, ge=1),
    limit: int = Query(10, ge=1, le=100),
    status: Optional[str] = None,
    db: Session = Depends(get_db)
):
    query = db.query(Booking)
    if status:
        query = query.filter(Booking.status == status)
    offset = (page - 1) * limit
    return query.offset(offset).limit(limit).all()


@app.get("/bookings/{booking_id}", response_model=BookingResponse)
def get_booking(booking_id: int, db: Session = Depends(get_db)):
    booking = db.query(Booking).filter(Booking.booking_id == booking_id).first()
    if not booking:
        raise HTTPException(status_code=404, detail="Бронирование не найдено")
    return booking


@app.post("/bookings", response_model=BookingResponse, status_code=201)
def create_booking(booking: BookingCreate, db: Session = Depends(get_db)):
    db_booking = Booking(**booking.model_dump())
    db.add(db_booking)
    try:
        db.commit()
        db.refresh(db_booking)
        return db_booking
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=400, detail=f"Ошибка: {str(e)}")


@app.put("/bookings/{booking_id}", response_model=BookingResponse)
def update_booking(booking_id: int, booking: BookingUpdate, db: Session = Depends(get_db)):
    db_booking = db.query(Booking).filter(Booking.booking_id == booking_id).first()
    if not db_booking:
        raise HTTPException(status_code=404, detail="Бронирование не найдено")
    for key, value in booking.model_dump(exclude_unset=True).items():
        setattr(db_booking, key, value)
    db.commit()
    db.refresh(db_booking)
    return db_booking


@app.delete("/bookings/{booking_id}", status_code=204)
def delete_booking(booking_id: int, db: Session = Depends(get_db)):
    db_booking = db.query(Booking).filter(Booking.booking_id == booking_id).first()
    if not db_booking:
        raise HTTPException(status_code=404, detail="Бронирование не найдено")
    db.delete(db_booking)
    db.commit()


# ============================================
# VIEWS (представления из 2-й лабы)
# ============================================

@app.get("/views/active-listings-with-rating")
def get_active_listings_with_rating(db: Session = Depends(get_db)):
    """Представление active_listings_with_rating (лаба 2)"""
    result = db.execute("SELECT * FROM active_listings_with_rating")
    return [dict(row) for row in result.mappings()]


@app.get("/views/host-financial-summary")
def get_host_financial_summary(db: Session = Depends(get_db)):
    """Представление host_financial_summary (лаба 2)"""
    result = db.execute("SELECT * FROM host_financial_summary")
    return [dict(row) for row in result.mappings()]


@app.get("/views/guest-activity-analytics")
def get_guest_activity_analytics(db: Session = Depends(get_db)):
    """Представление guest_activity_analytics (лаба 2)"""
    result = db.execute("SELECT * FROM guest_activity_analytics")
    return [dict(row) for row in result.mappings()]


# ============================================
# PROCEDURES (процедуры из 3-й лабы)
# ============================================

@app.post("/bookings/create-via-procedure")
def create_booking_via_procedure(
    listing_id: int,
    guest_id: int,
    start_date: str,
    end_date: str,
    guest_count: int,
    db: Session = Depends(get_db)
):
    """Вызов процедуры create_booking (лаба 3)"""
    try:
        result = db.execute(
            "CALL create_booking(:listing_id, :guest_id, :start_date, :end_date, :guest_count, NULL, NULL)",
            {
                "listing_id": listing_id,
                "guest_id": guest_id,
                "start_date": start_date,
                "end_date": end_date,
                "guest_count": guest_count,
            },
        )
        db.commit()
        return {"message": "Бронирование создано"}
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=400, detail=f"Ошибка: {str(e)}")


# ============================================
# REPORTS (агрегации и отчёты)
# ============================================

@app.get("/reports/host-stats", response_model=list[HostStatsResponse])
def get_host_stats(db: Session = Depends(get_db)):
    """Статистика по хостам из host_statistics (лаба 3)"""
    result = db.execute("SELECT * FROM host_statistics ORDER BY total_revenue DESC")
    return [dict(row) for row in result.mappings()]


@app.get("/reports/top-hosts")
def get_top_hosts(limit: int = 10, db: Session = Depends(get_db)):
    """Топ хостов по доходу"""
    result = db.execute(
        "SELECT * FROM host_financial_summary ORDER BY total_revenue DESC LIMIT :limit",
        {"limit": limit},
    )
    return [dict(row) for row in result.mappings()]


@app.get("/reports/bookings-by-status")
def get_bookings_by_status(db: Session = Depends(get_db)):
    """Количество бронирований по статусам"""
    result = db.query(Booking.status, func.count(Booking.booking_id)).group_by(Booking.status).all()
    return [{"status": status, "count": count} for status, count in result]


@app.get("/reports/listings-by-city")
def get_listings_by_city(db: Session = Depends(get_db)):
    """Количество объявлений по городам"""
    result = db.query(Listing.city, func.count(Listing.listing_id)).group_by(Listing.city).all()
    return [{"city": city, "count": count} for city, count in result]


@app.get("/reports/revenue-by-city")
def get_revenue_by_city(db: Session = Depends(get_db)):
    """Доход по городам"""
    result = db.execute("""
        SELECT l.city, SUM(b.total_price) as revenue, COUNT(b.booking_id) as bookings
        FROM bookings b
        JOIN listings l ON b.listing_id = l.listing_id
        WHERE b.status = 'completed'
        GROUP BY l.city
        ORDER BY revenue DESC
    """)
    return [dict(row) for row in result.mappings()]


# ============================================
# ЗАПУСК
# ============================================

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)