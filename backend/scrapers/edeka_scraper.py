import asyncio
from typing import List, Dict, Optional
from datetime import datetime, timedelta
import httpx
from bs4 import BeautifulSoup
from .base_scraper import BaseScraper


class EdekaScraper(BaseScraper):
    """
    Scraper for EDEKA deals

    EDEKA is franchise-based, so deals may vary by region.
    This scraper targets the national offers page.
    """

    def __init__(self):
        super().__init__(
            store_name='EDEKA',
            base_url='https://www.edeka.de'
        )

        self.headers = {
            'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
            'Accept-Language': 'de-DE,de;q=0.9,en-US;q=0.8,en;q=0.7',
            'Accept-Encoding': 'gzip, deflate, br',
            'DNT': '1',
            'Connection': 'keep-alive',
            'Upgrade-Insecure-Requests': '1',
            'Sec-Fetch-Dest': 'document',
            'Sec-Fetch-Mode': 'navigate',
            'Sec-Fetch-Site': 'none',
            'Cache-Control': 'max-age=0',
        }

    async def scrape_deals(self) -> List[Dict]:
        """Scrape current deals from EDEKA"""
        deals = []

        try:
            url = f"{self.base_url}/eh/angebote.jsp"

            async with httpx.AsyncClient(
                headers=self.headers,
                timeout=30.0,
                follow_redirects=True
            ) as client:

                await asyncio.sleep(2)

                response = await client.get(url)

                if response.status_code == 403:
                    self.logger.warning("EDEKA: Bot protection detected (403)")
                    return deals

                if response.status_code != 200:
                    self.logger.warning(f"EDEKA: Failed to fetch (status {response.status_code})")
                    return deals

                soup = BeautifulSoup(response.text, 'html.parser')

                # EDEKA offer selectors
                deal_items = soup.select(
                    '.offer-tile, .product-tile, .o-offers__item, '
                    'article[class*="offer"], .m-offer-tile'
                )

                if not deal_items:
                    self.logger.info("EDEKA: No deal items found with primary selectors, trying fallback")
                    deal_items = soup.select('[class*="offer"], [class*="product"], [class*="angebot"]')

                for item in deal_items[:50]:
                    deal = self._parse_deal_item(item)
                    if deal:
                        deals.append(deal)
                        await asyncio.sleep(0.1)

        except Exception as e:
            self.logger.error(f"Error scraping EDEKA: {e}")

        self.logger.info(f"EDEKA: Found {len(deals)} deals")
        return deals

    def _parse_deal_item(self, item) -> Optional[Dict]:
        """Parse a single deal item from HTML"""
        try:
            product_name = None
            for selector in [
                '.offer-tile__title', '.m-offer-tile__title',
                'h3', 'h4', '.title', '[class*="title"]', '[class*="name"]'
            ]:
                element = item.select_one(selector)
                if element:
                    product_name = element.get_text(strip=True)
                    break

            if not product_name:
                return None

            discount_price = None
            for selector in [
                '.offer-tile__price', '.m-offer-tile__price',
                '.price', '[class*="price"]'
            ]:
                element = item.select_one(selector)
                if element:
                    discount_price = self._parse_price(element.get_text())
                    if discount_price:
                        break

            if not discount_price:
                return None

            original_price = None
            for selector in [
                '.offer-tile__old-price', '.price--old',
                '.original-price', 'del', '[class*="old-price"]'
            ]:
                element = item.select_one(selector)
                if element:
                    original_price = self._parse_price(element.get_text())
                    break

            if not original_price:
                original_price = discount_price * 1.25

            image_url = None
            img = item.select_one('img')
            if img:
                image_url = img.get('src') or img.get('data-src') or img.get('data-lazy-src')
                if image_url and not image_url.startswith('http'):
                    image_url = f"{self.base_url}{image_url}"

            valid_from = datetime.now().replace(hour=0, minute=0, second=0, microsecond=0)
            valid_until = valid_from + timedelta(days=7)

            category = self._categorize_product(product_name)

            return self._create_deal(
                product_name=product_name,
                original_price=original_price,
                discount_price=discount_price,
                image_url=image_url,
                valid_from=valid_from,
                valid_until=valid_until,
                category=category
            )

        except Exception as e:
            self.logger.warning(f"Error parsing EDEKA deal item: {e}")
            return None

    def _categorize_product(self, product_name: str) -> str:
        """Categorize product based on name"""
        name_lower = product_name.lower()

        if any(word in name_lower for word in [
            'hähnchen', 'huhn', 'chicken', 'geflügel',
            'rind', 'beef', 'steak', 'hack', 'wurst',
            'schinken', 'salami', 'fleisch', 'schwein', 'pute'
        ]):
            return 'Fleisch & Wurst'

        if any(word in name_lower for word in [
            'apfel', 'banane', 'orange', 'tomate', 'gurke',
            'salat', 'karotte', 'paprika', 'obst', 'gemüse',
            'beeren', 'erdbeeren', 'trauben', 'kiwi', 'zucchini'
        ]):
            return 'Obst & Gemüse'

        if any(word in name_lower for word in [
            'milch', 'käse', 'joghurt', 'butter', 'sahne',
            'quark', 'frischkäse', 'cream', 'skyr'
        ]):
            return 'Milchprodukte'

        if any(word in name_lower for word in [
            'wasser', 'saft', 'limo', 'cola', 'bier',
            'wein', 'kaffee', 'tee', 'getränk', 'energy'
        ]):
            return 'Getränke'

        if any(word in name_lower for word in [
            'brot', 'brötchen', 'toast', 'kuchen', 'gebäck', 'croissant'
        ]):
            return 'Backwaren'

        if any(word in name_lower for word in [
            'tiefkühl', 'tk-', 'frozen', 'eis', 'pizza'
        ]):
            return 'Tiefkühlprodukte'

        if any(word in name_lower for word in [
            'fisch', 'lachs', 'thunfisch', 'garnele', 'shrimp'
        ]):
            return 'Fisch'

        return 'Sonstiges'
