import os
import tempfile
from typing import List, Dict, Optional
from pathlib import Path
from PIL import Image
import pytesseract
from pdf2image import convert_from_path
import re
from datetime import datetime, timedelta
import logging
import base64
import json
from openai import OpenAI

logger = logging.getLogger(__name__)


class OCRService:
    """Service for extracting text from images and PDFs"""

    def __init__(self):
        # Configure tesseract for German language
        self.tesseract_config = '--oem 3 --psm 6 -l deu'

        # Initialize OpenAI client
        api_key = os.getenv("OPENAI_API_KEY")
        self.openai_client = OpenAI(api_key=api_key) if api_key else None

    async def extract_text_from_image(self, image_path: str) -> str:
        """Extract text from image using OCR"""
        try:
            img = Image.open(image_path)
            text = pytesseract.image_to_string(img, config=self.tesseract_config)
            return text
        except Exception as e:
            logger.error(f"Error extracting text from image: {e}")
            return ""

    async def extract_text_from_pdf(self, pdf_path: str) -> str:
        """Extract text from PDF by converting to images"""
        try:
            # Convert PDF to images
            images = convert_from_path(pdf_path, dpi=300)

            all_text = []
            for i, image in enumerate(images):
                logger.info(f"Processing page {i + 1}/{len(images)}")
                text = pytesseract.image_to_string(image, config=self.tesseract_config)
                all_text.append(text)

            return "\n\n--- PAGE BREAK ---\n\n".join(all_text)

        except Exception as e:
            logger.error(f"Error extracting text from PDF: {e}")
            return ""

    async def extract_text_from_file(self, file_path: str) -> str:
        """Extract text from file (auto-detect type)"""
        file_ext = Path(file_path).suffix.lower()

        if file_ext == '.pdf':
            return await self.extract_text_from_pdf(file_path)
        elif file_ext in ['.jpg', '.jpeg', '.png', '.bmp', '.tiff']:
            return await self.extract_text_from_image(file_path)
        else:
            raise ValueError(f"Unsupported file type: {file_ext}")

    def encode_image(self, image_path: str) -> str:
        """Encode image to base64"""
        with open(image_path, "rb") as image_file:
            return base64.b64encode(image_file.read()).decode('utf-8')

    async def extract_deals_with_vision_api(
        self,
        file_path: str,
        store_name: str = "Unbekannt",
        on_page_complete = None
    ) -> List[Dict]:
        """Extract deals from file using OpenAI Vision API"""
        if not self.openai_client:
            raise ValueError("OpenAI API key not configured")

        try:
            file_ext = Path(file_path).suffix.lower()

            # Convert PDF to images
            if file_ext == '.pdf':
                images = convert_from_path(file_path, dpi=200)
            else:
                images = [Image.open(file_path)]

            all_deals = []

            for i, image in enumerate(images):
                logger.info(f"Processing page {i + 1}/{len(images)} with Vision API")

                # Save image temporarily
                with tempfile.NamedTemporaryFile(suffix='.jpg', delete=False) as tmp_file:
                    image.save(tmp_file.name, 'JPEG')
                    tmp_path = tmp_file.name

                try:
                    # Encode image
                    base64_image = self.encode_image(tmp_path)

                    # Call OpenAI Vision API
                    response = self.openai_client.chat.completions.create(
                        model="gpt-4o",
                        messages=[
                            {
                                "role": "user",
                                "content": [
                                    {
                                        "type": "text",
                                        "text": f"""Analysiere dieses Supermarkt-Prospekt von {store_name} und extrahiere ALLE Angebote.

Für jedes Angebot, extrahiere:
- product_name: Name des Produkts
- original_price: Originalpreis (falls sichtbar, sonst berechne aus Rabatt)
- discount_price: Angebotspreis
- discount_percentage: Rabatt in Prozent
- valid_from: Gültig ab (Format: YYYY-MM-DD, falls nicht sichtbar nutze heute)
- valid_until: Gültig bis (Format: YYYY-MM-DD, falls nicht sichtbar nutze +7 Tage)
- category: Kategorie (Fleisch & Wurst, Obst & Gemüse, Milchprodukte, Getränke, Backwaren, Tiefkühlprodukte, oder Sonstiges)
- description: Kurze Beschreibung mit allen Details (Marke, Menge, etc.)

Gib die Antwort als JSON-Array zurück:
[
  {{
    "product_name": "...",
    "original_price": 0.00,
    "discount_price": 0.00,
    "discount_percentage": 0,
    "valid_from": "2024-12-24",
    "valid_until": "2024-12-31",
    "category": "...",
    "description": "..."
  }}
]

WICHTIG: Extrahiere ALLE sichtbaren Angebote auf dieser Seite. Sei präzise bei Preisen und Prozenten."""
                                    },
                                    {
                                        "type": "image_url",
                                        "image_url": {
                                            "url": f"data:image/jpeg;base64,{base64_image}"
                                        }
                                    }
                                ]
                            }
                        ],
                        max_tokens=4096,
                        temperature=0.1
                    )

                    # Parse response
                    content = response.choices[0].message.content
                    logger.info(f"Vision API response: {content[:200]}...")

                    # Extract JSON from response
                    # Sometimes the API wraps it in ```json ... ```
                    json_match = re.search(r'```json\s*(.*?)\s*```', content, re.DOTALL)
                    if json_match:
                        content = json_match.group(1)

                    deals = json.loads(content)

                    # Add store name and convert dates to ISO format
                    for deal in deals:
                        deal['store_name'] = store_name
                        deal['image_url'] = ''

                        # Ensure dates are in ISO format
                        if 'valid_from' in deal:
                            try:
                                # Parse and convert to datetime
                                date_str = deal['valid_from']
                                if 'T' not in date_str:
                                    date_str += 'T00:00:00'
                                deal['valid_from'] = date_str
                            except:
                                deal['valid_from'] = datetime.now().isoformat()

                        if 'valid_until' in deal:
                            try:
                                date_str = deal['valid_until']
                                if 'T' not in date_str:
                                    date_str += 'T23:59:59'
                                deal['valid_until'] = date_str
                            except:
                                deal['valid_until'] = (datetime.now() + timedelta(days=7)).isoformat()

                    all_deals.extend(deals)
                    logger.info(f"Extracted {len(deals)} deals from page {i + 1}")

                    # Call callback after each page
                    if on_page_complete:
                        on_page_complete(deals)

                finally:
                    # Clean up temp file
                    os.unlink(tmp_path)

            logger.info(f"Total deals extracted: {len(all_deals)}")
            return all_deals

        except Exception as e:
            logger.error(f"Error extracting deals with Vision API: {e}")
            raise


class DealExtractor:
    """Extract deal information from OCR text"""

    def __init__(self):
        self.ocr_service = OCRService()

    def _parse_price(self, text: str) -> Optional[float]:
        """Parse price from text"""
        # Match patterns like: 4,99€ 4.99€ 4,99 € 4.99 EUR
        price_patterns = [
            r'(\d+)[,.](\d{2})\s*€',
            r'(\d+)[,.](\d{2})\s*EUR',
            r'€\s*(\d+)[,.](\d{2})',
        ]

        for pattern in price_patterns:
            match = re.search(pattern, text)
            if match:
                if len(match.groups()) == 2:
                    euros, cents = match.groups()
                    return float(f"{euros}.{cents}")

        return None

    def _parse_percentage(self, text: str) -> Optional[int]:
        """Parse percentage discount from text"""
        # Match patterns like: -30% 30% SPAREN 30 PROZENT
        patterns = [
            r'-?(\d+)\s*%',
            r'(\d+)\s*PROZENT',
        ]

        for pattern in patterns:
            match = re.search(pattern, text, re.IGNORECASE)
            if match:
                return int(match.group(1))

        return None

    def _parse_dates(self, text: str) -> tuple[Optional[datetime], Optional[datetime]]:
        """Parse validity dates from text"""
        # Common German date patterns
        # "gültig vom 23.12. bis 30.12."
        # "23.12.2025 - 30.12.2025"
        # "ab 23.12."

        date_range_pattern = r'(\d{1,2})\.(\d{1,2})\.?(?:(\d{4}))?.*?bis.*?(\d{1,2})\.(\d{1,2})\.?(?:(\d{4}))?'
        match = re.search(date_range_pattern, text, re.IGNORECASE)

        if match:
            day1, month1, year1, day2, month2, year2 = match.groups()
            current_year = datetime.now().year

            year1 = int(year1) if year1 else current_year
            year2 = int(year2) if year2 else current_year

            try:
                valid_from = datetime(year1, int(month1), int(day1))
                valid_until = datetime(year2, int(month2), int(day2), 23, 59, 59)
                return valid_from, valid_until
            except ValueError:
                pass

        # Default: today to +7 days
        valid_from = datetime.now().replace(hour=0, minute=0, second=0, microsecond=0)
        valid_until = valid_from + timedelta(days=7)
        return valid_from, valid_until

    def extract_deals_from_text(
        self,
        text: str,
        store_name: str = "Unbekannt"
    ) -> List[Dict]:
        """
        Extract deals from OCR text using pattern matching

        This is a simple rule-based extractor.
        For better results, use AI-powered extraction (see extract_deals_with_ai)
        """
        deals = []

        # Split by common delimiters
        # Prospekte often have deals separated by visual breaks
        sections = re.split(r'\n{2,}|---', text)

        for section in sections:
            if len(section.strip()) < 10:
                continue

            # Try to find product name (usually capitalized or bold)
            lines = section.strip().split('\n')
            product_name = None

            for line in lines:
                # Product names are often in CAPS or Title Case
                if len(line.strip()) > 3 and any(c.isupper() for c in line):
                    product_name = line.strip()
                    break

            if not product_name:
                continue

            # Find prices
            prices = []
            for line in lines:
                price = self._parse_price(line)
                if price:
                    prices.append(price)

            if not prices:
                continue

            # Determine original and discount price
            discount_price = min(prices)
            original_price = max(prices) if len(prices) > 1 else discount_price * 1.25

            # Find discount percentage
            discount_percentage = self._parse_percentage(section)
            if not discount_percentage:
                discount_percentage = int(((original_price - discount_price) / original_price) * 100)

            # Find dates
            valid_from, valid_until = self._parse_dates(text)

            # Categorize product
            category = self._categorize_product(product_name)

            deal = {
                'product_name': product_name,
                'store_name': store_name,
                'original_price': round(original_price, 2),
                'discount_price': round(discount_price, 2),
                'discount_percentage': discount_percentage,
                'image_url': '',
                'valid_from': valid_from.isoformat(),
                'valid_until': valid_until.isoformat(),
                'category': category,
                'description': section.strip()[:200]
            }

            deals.append(deal)

        logger.info(f"Extracted {len(deals)} deals using pattern matching")
        return deals

    def _categorize_product(self, product_name: str) -> str:
        """Categorize product based on name"""
        name_lower = product_name.lower()

        categories = {
            'Fleisch & Wurst': ['hähnchen', 'huhn', 'chicken', 'rind', 'beef', 'steak', 'hack', 'wurst', 'schinken', 'salami', 'fleisch', 'schwein'],
            'Obst & Gemüse': ['apfel', 'banane', 'orange', 'tomate', 'gurke', 'salat', 'karotte', 'paprika', 'obst', 'gemüse', 'beeren'],
            'Milchprodukte': ['milch', 'käse', 'joghurt', 'butter', 'sahne', 'quark', 'frischkäse'],
            'Getränke': ['wasser', 'saft', 'limo', 'cola', 'bier', 'wein', 'kaffee', 'tee'],
            'Backwaren': ['brot', 'brötchen', 'toast', 'kuchen', 'gebäck'],
            'Tiefkühlprodukte': ['tiefkühl', 'tk-', 'frozen', 'eis', 'pizza'],
        }

        for category, keywords in categories.items():
            if any(keyword in name_lower for keyword in keywords):
                return category

        return 'Sonstiges'

    async def extract_deals_from_file(
        self,
        file_path: str,
        store_name: str = "Unbekannt",
        use_ai: bool = True,
        on_page_complete = None
    ) -> List[Dict]:
        """Extract deals from uploaded file"""
        # Try AI-powered extraction first if enabled
        logger.info(f"OpenAI client available: {self.ocr_service.openai_client is not None}")
        if use_ai and self.ocr_service.openai_client:
            try:
                logger.info("Using AI-powered extraction with Vision API")
                deals = await self.ocr_service.extract_deals_with_vision_api(
                    file_path,
                    store_name,
                    on_page_complete=on_page_complete
                )
                if deals:
                    return deals
            except Exception as e:
                logger.error(f"AI extraction failed, falling back to OCR: {e}", exc_info=True)

        # Fallback: Extract text using OCR
        text = await self.ocr_service.extract_text_from_file(file_path)

        if not text.strip():
            logger.warning("No text extracted from file")
            return []

        # Extract deals using pattern matching
        deals = self.extract_deals_from_text(text, store_name)

        return deals
