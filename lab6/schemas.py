# schemas.py
# Pydantic схемы — валидация входных/выходных данных

from pydantic import BaseModel, Field, EmailStr
from typing import Optional
from datetime import date, datetime
from decimal import Decimal


# ========== USERS ==========
class UserCreate(BaseModel):
    email: str
    password_hash: str
    full_name: str
    phone: Optional[str] = None
    role: str = "guest"

class UserUpdate(BaseModel):
    email: Optional[str] = None
    full_name: Optional[str] = None
    phone: Optional[str] = None
    is_verified: Optional[bool] = None

class UserResponse(BaseModel):
    user_id: int
    email: str
    full_name: str
    phone: Optional[str] = None
    role: str
    is_verified: bool
    created_at: Optional[datetime] = None

    class Config:
        from_attributes = True


# ========== LISTINGS ==========
class ListingCreate(BaseModel):
    host_id: int
    title: str
    description: Optional[str] = None
    property_type: str
    price_per_night: Decimal
    max_guests: int = 1
    bedrooms: int = 1
    bathrooms: float = 1.0
    address: str
    city: str
    country: str = "Россия"

class ListingUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    price_per_night: Optional[Decimal] = None
    max_guests: Optional[int] = None
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


# ========== BOOKINGS ==========
class BookingCreate(BaseModel):
    listing_id: int
    guest_id: int
    start_date: date
    end_date: date
    guest_count: int = 1
    total_price: Decimal

class BookingUpdate(BaseModel):
    status: Optional[str] = None
    guest_count: Optional[int] = None

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


# ========== AGGREGATIONS ==========
class HostStatsResponse(BaseModel):
    host_id: int
    total_listings: int
    active_listings: int
    total_completed_bookings: int
    total_revenue: Decimal
    avg_rating: float