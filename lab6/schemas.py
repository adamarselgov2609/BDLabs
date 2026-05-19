# schemas.py
# Pydantic схемы — валидация входных/выходных данных

from pydantic import BaseModel, Field, EmailStr
from typing import Optional
from datetime import date, datetime
from decimal import Decimal


# =========================================================
# USERS
# =========================================================

class UserCreate(BaseModel):
    email: EmailStr
    password_hash: str = Field(min_length=6)
    full_name: str = Field(min_length=2)
    phone: Optional[str] = None
    role: str = Field(default="guest")


class UserUpdate(BaseModel):
    email: Optional[EmailStr] = None
    full_name: Optional[str] = Field(default=None, min_length=2)
    phone: Optional[str] = None
    is_verified: Optional[bool] = None


class UserResponse(BaseModel):
    user_id: int
    email: EmailStr
    full_name: str
    phone: Optional[str]
    role: str
    is_verified: bool
    created_at: Optional[datetime] = None

    class Config:
        from_attributes = True


# =========================================================
# LISTINGS
# =========================================================

class ListingCreate(BaseModel):
    host_id: int

    title: str = Field(min_length=3)
    description: Optional[str] = None

    property_type: str

    price_per_night: Decimal = Field(gt=0)

    max_guests: int = Field(gt=0)
    bedrooms: int = Field(gt=0)
    bathrooms: float = Field(gt=0)

    address: str
    city: str
    country: str = "Russia"


class ListingUpdate(BaseModel):
    title: Optional[str] = Field(default=None, min_length=3)
    description: Optional[str] = None

    price_per_night: Optional[Decimal] = Field(default=None, gt=0)

    max_guests: Optional[int] = Field(default=None, gt=0)

    is_active: Optional[bool] = None


class ListingResponse(BaseModel):
    listing_id: int
    host_id: int

    title: str
    property_type: str

    price_per_night: Decimal

    max_guests: int
    city: str

    is_active: bool
    created_at: Optional[datetime] = None

    class Config:
        from_attributes = True


# =========================================================
# BOOKINGS
# =========================================================

class BookingCreate(BaseModel):
    listing_id: int
    guest_id: int

    start_date: date
    end_date: date

    guest_count: int = Field(gt=0)

    total_price: Decimal = Field(ge=0)


class BookingUpdate(BaseModel):
    status: Optional[str] = None
    guest_count: Optional[int] = Field(default=None, gt=0)


class BookingResponse(BaseModel):
    booking_id: int
    listing_id: int
    guest_id: int

    start_date: date
    end_date: date

    guest_count: int
    total_price: Decimal

    status: str
    created_at: Optional[datetime] = None

    class Config:
        from_attributes = True


# =========================================================
# HOST STATS
# =========================================================

class HostStatsResponse(BaseModel):
    host_id: int

    total_listings: int
    active_listings: int

    total_completed_bookings: int

    total_revenue: Decimal

    avg_rating: Optional[float] = None