from abc import ABC, abstractmethod
from typing import List, Dict, Optional
from datetime import datetime
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class BaseScraper(ABC):
    """Abstract base class for supermarket scrapers"""

    def __init__(self, store_name: str, base_url: str):
        self.store_name = store_name
        self.base_url = base_url
        self.logger = logger

    @abstractmethod
    async def scrape_deals(self) -> List[Dict]:
        """
        Scrape deals from the supermarket website

        Returns:
            List of deal dictionaries with structure:
            {
                'product_name': str,
                'store_name': str,
                'original_price': float,
                'discount_price': float,
                'discount_percentage': int,
                'image_url': str,
                'valid_from': datetime,
                'valid_until': datetime,
                'category': str,
                'description': str (optional)
            }
        """
        pass

    def _calculate_discount_percentage(
        self,
        original_price: float,
        discount_price: float
    ) -> int:
        """Calculate discount percentage"""
        if original_price <= 0:
            return 0
        return int(((original_price - discount_price) / original_price) * 100)

    def _parse_price(self, price_str: str) -> Optional[float]:
        """Parse price string to float"""
        try:
            # Remove currency symbols and convert to float
            cleaned = price_str.replace('€', '').replace(',', '.').strip()
            return float(cleaned)
        except (ValueError, AttributeError):
            self.logger.warning(f"Could not parse price: {price_str}")
            return None

    def _create_deal(
        self,
        product_name: str,
        discount_price: float,
        original_price: Optional[float] = None,
        image_url: Optional[str] = None,
        category: Optional[str] = None,
        description: Optional[str] = None,
        valid_from: Optional[datetime] = None,
        valid_until: Optional[datetime] = None
    ) -> Dict:
        """Create a standardized deal dictionary"""

        # Calculate original price if not provided (assume 20% discount)
        if original_price is None:
            original_price = discount_price * 1.25

        # Set default dates if not provided
        if valid_from is None:
            valid_from = datetime.now()
        if valid_until is None:
            valid_until = datetime.now().replace(hour=23, minute=59, second=59)
            # Add 7 days for weekly deals
            from datetime import timedelta
            valid_until = valid_until + timedelta(days=7)

        discount_percentage = self._calculate_discount_percentage(
            original_price,
            discount_price
        )

        return {
            'product_name': product_name,
            'store_name': self.store_name,
            'original_price': round(original_price, 2),
            'discount_price': round(discount_price, 2),
            'discount_percentage': discount_percentage,
            'image_url': image_url or '',
            'valid_from': valid_from.isoformat(),
            'valid_until': valid_until.isoformat(),
            'category': category or 'Sonstiges',
            'description': description or ''
        }
