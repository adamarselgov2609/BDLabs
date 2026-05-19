# models.py
# ORM модели SQLAlchemy — структура базы данных

from sqlalchemy import (
    Column,
    Integer,
    BigInteger,
    String,
    Text,
    Numeric,
    Boolean,
    Date,
    DateTime,
    ForeignKey,
    CheckConstraint,
    func
)
from sqlalchemy.orm import relationship

from database import Base

# =========================================================
# USER
# =========================================================

class User(Base):
    __tablename__ = "users"

    user_id = Column(BigInteger, primary_key=True, autoincrement=True)

    email = Column(String(255), unique=True, nullable=False)
    password_hash = Column(String(255), nullable=False)

    full_name = Column(String(255), nullable=False)
    phone = Column(String(20))

    role = Column(String(50), nullable=False, default="guest")
    is_verified = Column(Boolean, default=False)

    verification_date = Column(DateTime)

    created_at = Column(DateTime, server_default=func.now())

    # relationships
    listings = relationship(
        "Listing",
        back_populates="host",
        cascade="all, delete"
    )

    bookings = relationship(
        "Booking",
        back_populates="guest",
        foreign_keys="Booking.guest_id",
        cascade="all, delete"
    )


# =========================================================
# LISTING
# =========================================================

class Listing(Base):
    __tablename__ = "listings"

    listing_id = Column(BigInteger, primary_key=True, autoincrement=True)

    host_id = Column(
        BigInteger,
        ForeignKey("users.user_id", ondelete="CASCADE"),
        nullable=False
    )

    title = Column(String(255), nullable=False)
    description = Column(Text)

    property_type = Column(String(100), nullable=False)

    price_per_night = Column(Numeric(10, 2), nullable=False)

    max_guests = Column(Integer, nullable=False, default=1)
    bedrooms = Column(Integer, nullable=False, default=1)
    bathrooms = Column(Numeric(3, 1), nullable=False, default=1.0)

    address = Column(Text, nullable=False)
    city = Column(String(100), nullable=False)
    country = Column(String(100), nullable=False)

    is_active = Column(Boolean, default=True)

    created_at = Column(DateTime, server_default=func.now())

    # constraints
    __table_args__ = (
        CheckConstraint("price_per_night > 0", name="check_price_positive"),
        CheckConstraint("max_guests > 0", name="check_max_guests_positive"),
        CheckConstraint("bedrooms > 0", name="check_bedrooms_positive"),
        CheckConstraint("bathrooms > 0", name="check_bathrooms_positive"),
    )

    # relationships
    host = relationship("User", back_populates="listings")

    bookings = relationship(
        "Booking",
        back_populates="listing",
        cascade="all, delete"
    )


# =========================================================
# BOOKING
# =========================================================

class Booking(Base):
    __tablename__ = "bookings"

    booking_id = Column(BigInteger, primary_key=True, autoincrement=True)

    listing_id = Column(
        BigInteger,
        ForeignKey("listings.listing_id", ondelete="CASCADE"),
        nullable=False
    )

    guest_id = Column(
        BigInteger,
        ForeignKey("users.user_id", ondelete="CASCADE"),
        nullable=False
    )

    start_date = Column(Date, nullable=False)
    end_date = Column(Date, nullable=False)

    guest_count = Column(Integer, nullable=False, default=1)

    total_price = Column(Numeric(10, 2), nullable=False)

    status = Column(String(50), default="pending")

    created_at = Column(DateTime, server_default=func.now())

    # constraints
    __table_args__ = (
        CheckConstraint("guest_count > 0", name="check_guest_count_positive"),
    )

    # relationships
    listing = relationship("Listing", back_populates="bookings")

    guest = relationship(
        "User",
        back_populates="bookings",
        foreign_keys=[guest_id]
    )

    review = relationship(
        "Review",
        back_populates="booking",
        uselist=False,
        cascade="all, delete"
    )

    payment = relationship(
        "Payment",
        back_populates="booking",
        uselist=False,
        cascade="all, delete"
    )


# =========================================================
# REVIEW
# =========================================================

class Review(Base):
    __tablename__ = "reviews"

    review_id = Column(BigInteger, primary_key=True, autoincrement=True)

    booking_id = Column(
        BigInteger,
        ForeignKey("bookings.booking_id", ondelete="CASCADE"),
        unique=True,
        nullable=False
    )

    rating = Column(Integer, nullable=False)
    comment = Column(Text)

    host_response = Column(Text)
    response_date = Column(DateTime)

    created_at = Column(DateTime, server_default=func.now())

    # constraints
    __table_args__ = (
        CheckConstraint("rating >= 1 AND rating <= 5", name="check_rating_range"),
    )

    # relationship
    booking = relationship("Booking", back_populates="review")


# =========================================================
# PAYMENT
# =========================================================

class Payment(Base):
    __tablename__ = "payments"

    payment_id = Column(BigInteger, primary_key=True, autoincrement=True)

    booking_id = Column(
        BigInteger,
        ForeignKey("bookings.booking_id", ondelete="CASCADE"),
        unique=True,
        nullable=False
    )

    amount = Column(Numeric(10, 2), nullable=False)

    payment_date = Column(DateTime, server_default=func.now())

    payment_method = Column(String(50), nullable=False)

    status = Column(String(20), default="pending")

    transaction_id = Column(String(100), unique=True)

    # relationship
    booking = relationship("Booking", back_populates="payment")