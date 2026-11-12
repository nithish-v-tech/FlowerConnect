"""initial schema

Revision ID: 0001_initial_schema
Revises: 
Create Date: 2026-11-04 22:00:00.000000

"""
from alembic import op
import sqlalchemy as sa

revision = '0001_initial_schema'
down_revision = None
branch_labels = None
depends_on = None

def upgrade() -> None:
    # Users table
    op.create_table(
        'users',
        sa.Column('id', sa.String(length=36), nullable=False),
        sa.Column('email', sa.String(length=120), nullable=False),
        sa.Column('phone', sa.String(length=20), nullable=False),
        sa.Column('full_name', sa.String(length=100), nullable=False),
        sa.Column('hashed_password', sa.String(length=255), nullable=False),
        sa.Column('role', sa.String(length=50), nullable=False),
        sa.Column('address', sa.String(length=255), nullable=True),
        sa.Column('is_active', sa.Boolean(), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=True),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_users_email'), 'users', ['email'], unique=True)
    op.create_index(op.f('ix_users_phone'), 'users', ['phone'], unique=True)

    # Shops table
    op.create_table(
        'shops',
        sa.Column('id', sa.String(length=36), nullable=False),
        sa.Column('user_id', sa.String(length=36), nullable=False),
        sa.Column('name', sa.String(length=120), nullable=False),
        sa.Column('shop_type', sa.String(length=50), nullable=False),
        sa.Column('address', sa.String(length=255), nullable=False),
        sa.Column('latitude', sa.Float(), nullable=False),
        sa.Column('longitude', sa.Float(), nullable=False),
        sa.Column('rating', sa.Float(), nullable=True),
        sa.Column('total_reviews', sa.Integer(), nullable=True),
        sa.Column('image_url', sa.String(length=255), nullable=True),
        sa.Column('is_verified', sa.Boolean(), nullable=True),
        sa.Column('is_featured', sa.Boolean(), nullable=True),
        sa.Column('is_open', sa.Boolean(), nullable=True),
        sa.Column('owner_name', sa.String(length=100), nullable=False),
        sa.Column('contact_phone', sa.String(length=20), nullable=False),
        sa.Column('daily_rates', sa.JSON(), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=True),
        sa.ForeignKeyConstraint(['user_id'], ['users.id']),
        sa.PrimaryKeyConstraint('id')
    )

    # Products table
    op.create_table(
        'products',
        sa.Column('id', sa.String(length=36), nullable=False),
        sa.Column('shop_id', sa.String(length=36), nullable=False),
        sa.Column('name', sa.String(length=150), nullable=False),
        sa.Column('description', sa.String(length=500), nullable=True),
        sa.Column('category', sa.String(length=50), nullable=False),
        sa.Column('price', sa.Float(), nullable=False),
        sa.Column('original_price', sa.Float(), nullable=True),
        sa.Column('unit', sa.String(length=50), nullable=True),
        sa.Column('image_url', sa.String(length=255), nullable=True),
        sa.Column('rating', sa.Float(), nullable=True),
        sa.Column('reviews_count', sa.Integer(), nullable=True),
        sa.Column('in_stock', sa.Boolean(), nullable=True),
        sa.Column('is_bestseller', sa.Boolean(), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=True),
        sa.ForeignKeyConstraint(['shop_id'], ['shops.id']),
        sa.PrimaryKeyConstraint('id')
    )

    # RFQ Requests table
    op.create_table(
        'rfq_requests',
        sa.Column('id', sa.String(length=36), nullable=False),
        sa.Column('customer_id', sa.String(length=36), nullable=False),
        sa.Column('customer_name', sa.String(length=100), nullable=False),
        sa.Column('title', sa.String(length=200), nullable=False),
        sa.Column('flower_type', sa.String(length=100), nullable=False),
        sa.Column('quantity_description', sa.String(length=200), nullable=False),
        sa.Column('occasion', sa.String(length=100), nullable=True),
        sa.Column('delivery_preference', sa.String(length=50), nullable=False),
        sa.Column('delivery_address', sa.String(length=255), nullable=False),
        sa.Column('latitude', sa.Float(), nullable=False),
        sa.Column('longitude', sa.Float(), nullable=False),
        sa.Column('target_budget', sa.Float(), nullable=True),
        sa.Column('need_by', sa.DateTime(), nullable=False),
        sa.Column('status', sa.String(length=50), nullable=False),
        sa.Column('accepted_quotation_id', sa.String(length=36), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=True),
        sa.Column('expires_at', sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(['customer_id'], ['users.id']),
        sa.PrimaryKeyConstraint('id')
    )

    # Quotations table
    op.create_table(
        'quotations',
        sa.Column('id', sa.String(length=36), nullable=False),
        sa.Column('rfq_id', sa.String(length=36), nullable=False),
        sa.Column('merchant_id', sa.String(length=36), nullable=False),
        sa.Column('shop_name', sa.String(length=120), nullable=False),
        sa.Column('merchant_phone', sa.String(length=20), nullable=False),
        sa.Column('merchant_rating', sa.Float(), nullable=True),
        sa.Column('distance_km', sa.Float(), nullable=False),
        sa.Column('quoted_price', sa.Float(), nullable=False),
        sa.Column('delivery_fee', sa.Float(), nullable=True),
        sa.Column('prep_time_minutes', sa.Integer(), nullable=True),
        sa.Column('notes', sa.String(length=500), nullable=True),
        sa.Column('freshness_guarantee', sa.String(length=200), nullable=True),
        sa.Column('status', sa.String(length=50), nullable=False),
        sa.Column('submitted_at', sa.DateTime(), nullable=True),
        sa.Column('expires_at', sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(['merchant_id'], ['shops.id']),
        sa.ForeignKeyConstraint(['rfq_id'], ['rfq_requests.id']),
        sa.PrimaryKeyConstraint('id')
    )

    # Orders table
    op.create_table(
        'orders',
        sa.Column('id', sa.String(length=36), nullable=False),
        sa.Column('customer_id', sa.String(length=36), nullable=False),
        sa.Column('customer_name', sa.String(length=100), nullable=False),
        sa.Column('customer_phone', sa.String(length=20), nullable=False),
        sa.Column('shop_id', sa.String(length=36), nullable=False),
        sa.Column('shop_name', sa.String(length=120), nullable=False),
        sa.Column('quotation_id', sa.String(length=36), nullable=True),
        sa.Column('items_json', sa.JSON(), nullable=False),
        sa.Column('items_total', sa.Float(), nullable=False),
        sa.Column('delivery_fee', sa.Float(), nullable=True),
        sa.Column('platform_commission', sa.Float(), nullable=True),
        sa.Column('grand_total', sa.Float(), nullable=False),
        sa.Column('fulfillment', sa.String(length=50), nullable=False),
        sa.Column('payment_method', sa.String(length=50), nullable=False),
        sa.Column('payment_status', sa.String(length=50), nullable=False),
        sa.Column('status', sa.String(length=50), nullable=False),
        sa.Column('delivery_address', sa.String(length=255), nullable=False),
        sa.Column('delivery_otp', sa.String(length=6), nullable=True),
        sa.Column('driver_id', sa.String(length=36), nullable=True),
        sa.Column('driver_name', sa.String(length=100), nullable=True),
        sa.Column('driver_phone', sa.String(length=20), nullable=True),
        sa.Column('is_surprise_delivery', sa.Boolean(), nullable=True),
        sa.Column('surprise_recipient_name', sa.String(length=100), nullable=True),
        sa.Column('surprise_note', sa.String(length=500), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=True),
        sa.ForeignKeyConstraint(['customer_id'], ['users.id']),
        sa.ForeignKeyConstraint(['shop_id'], ['shops.id']),
        sa.PrimaryKeyConstraint('id')
    )

def downgrade() -> None:
    op.drop_table('orders')
    op.drop_table('quotations')
    op.drop_table('rfq_requests')
    op.drop_table('products')
    op.drop_table('shops')
    op.drop_table('users')

