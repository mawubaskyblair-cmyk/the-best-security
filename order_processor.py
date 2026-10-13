"""
E-Commerce Order Processor Module
Language: Python 3
Description: Manages order placement, item validation, discount calculation,
             and dispatches fulfillment tasks to system components.
"""

import time
import uuid
import datetime
from typing import List, Dict, Any, Optional


class OrderItem:
    """Represents an individual item line in a customer order."""
    def __init__(self, sku: str, quantity: int, unit_price: float):
        self.sku = sku
        self.quantity = quantity
        self.unit_price = unit_price

    def get_subtotal(self) -> float:
        return self.quantity * self.unit_price


class Order:
    """Encapsulates customer order attributes and total processing logic."""
    def __init__(self, customer_id: str, items: List[OrderItem]):
        self.order_id = f"ORD-{uuid.uuid4().hex[:8].upper()}"
        self.customer_id = customer_id
        self.items = items
        self.status = "PENDING"
        self.created_at = datetime.datetime.now().isoformat()
        self.discount_rate = 0.0

    def apply_discount(self, promo_code: str) -> bool:
        """Applies promotional discounts based on valid promo codes."""
        if promo_code == "SAVE10" and self.calculate_total() > 50.0:
            self.discount_rate = 0.10
            return True
        elif promo_code == "VIP20":
            self.discount_rate = 0.20
            return True
        return False

    def calculate_total(self) -> float:
        subtotal = sum(item.get_subtotal() for item in self.items)
        return round(subtotal * (1.0 - self.discount_rate), 2)


class OrderProcessingEngine:
    """Core workflow coordinator for intake, stock verification, and dispatch."""
    
    def __init__(self):
        self.active_orders: Dict[str, Order] = {}
        self.processed_count = 0

    def submit_order(self, customer_id: str, items: List[OrderItem], promo: Optional[str] = None) -> Order:
        new_order = Order(customer_id, items)
        if promo:
            applied = new_order.apply_discount(promo)
            if applied:
                print(f"[{new_order.order_id}] Applied promo code '{promo}' successfully.")
        
        self.active_orders[new_order.order_id] = new_order
        print(f"[{new_order.order_id}] Order created for Customer {customer_id}. Items count: {len(items)}")
        return new_order

    def validate_and_reserve_stock(self, order_id: str, stock_catalog: Dict[str, int]) -> bool:
        order = self.active_orders.get(order_id)
        if not order:
            return False

        for item in order.items:
            available = stock_catalog.get(item.sku, 0)
            if available < item.quantity:
                order.status = "CANCELLED_OUT_OF_STOCK"
                print(f"[{order_id}] Insufficient stock for SKU: {item.sku} (Req: {item.quantity}, Avail: {available})")
                return False

        # Reserve stock
        for item in order.items:
            stock_catalog[item.sku] -= item.quantity
        
        order.status = "STOCK_RESERVED"
        print(f"[{order_id}] Stock reserved successfully. Total: ${order.calculate_total()}")
        return True

    def dispatch_to_fulfillment(self, order_id: str) -> None:
        order = self.active_orders.get(order_id)
        if order and order.status == "STOCK_RESERVED":
            order.status = "DISPATCHED"
            self.processed_count += 1
            print(f"[{order_id}] Dispatched to warehouse fulfillment queue.")


if __name__ == "__main__":
    catalog = {"SKU-A100": 50, "SKU-B200": 5, "SKU-C300": 100}
    engine = OrderProcessingEngine()

    cart = [OrderItem("SKU-A100", 2, 29.99), OrderItem("SKU-B200", 1, 149.50)]
    ord_1 = engine.submit_order("CUST-9982", cart, promo="SAVE10")
    
    if engine.validate_and_reserve_stock(ord_1.order_id, catalog):
        engine.dispatch_to_fulfillment(ord_1.order_id)

    print(f"\nRemaining Catalog Stock: {catalog}")
    print(f"Engine Processed Orders Count: {engine.processed_count}")