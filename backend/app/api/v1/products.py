import uuid
from fastapi import APIRouter, HTTPException, Depends, Query, status
from typing import List, Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.core.database import get_db
from app.models.product import Product, ProductCategory
from app.schemas.product import ProductResponse, ProductCreate

router = APIRouter(prefix="/products", tags=["Products & Stems"])

@router.get("/", response_model=List[ProductResponse])
async def list_products(
    shop_id: Optional[str] = None,
    category: Optional[ProductCategory] = None,
    db: AsyncSession = Depends(get_db)
):
    query = select(Product)
    if shop_id:
        query = query.where(Product.shop_id == shop_id)
    if category:
        query = query.where(Product.category == category)

    result = await db.execute(query)
    return result.scalars().all()

@router.get("/{product_id}", response_model=ProductResponse)
async def get_product(product_id: str, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Product).where(Product.id == product_id))
    product = result.scalars().first()
    if not product:
        raise HTTPException(status_code=404, detail="Product not found")
    return product

@router.post("/", response_model=ProductResponse, status_code=status.HTTP_201_CREATED)
async def create_product(payload: ProductCreate, db: AsyncSession = Depends(get_db)):
    product = Product(
        id=f"prod_{uuid.uuid4().hex[:8]}",
        shop_id=payload.shop_id,
        name=payload.name,
        description=payload.description,
        category=payload.category,
        price=payload.price,
        original_price=payload.original_price,
        unit=payload.unit,
        image_url=payload.image_url,
        rating=4.8,
        reviews_count=0,
        in_stock=payload.in_stock,
        is_bestseller=payload.is_bestseller,
    )
    db.add(product)
    await db.commit()
    await db.refresh(product)
    return product

@router.patch("/{product_id}/stock", response_model=ProductResponse)
async def toggle_stock(product_id: str, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Product).where(Product.id == product_id))
    product = result.scalars().first()
    if not product:
        raise HTTPException(status_code=404, detail="Product not found")

    product.in_stock = not product.in_stock
    await db.commit()
    await db.refresh(product)
    return product
