"""
Chefkoch.de Recipe Scraper
Extracts recipe data from Chefkoch.de URLs
"""

import re
import requests
from bs4 import BeautifulSoup
from typing import Dict, List, Optional
import json


class ChefkochScraper:
    """Scraper for Chefkoch.de recipes"""

    def __init__(self):
        self.headers = {
            'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
        }

    def scrape_recipe(self, url: str) -> Dict:
        """
        Scrape a recipe from Chefkoch.de

        Args:
            url: The Chefkoch.de recipe URL

        Returns:
            Dictionary containing recipe data
        """
        try:
            response = requests.get(url, headers=self.headers, timeout=10)
            response.raise_for_status()

            soup = BeautifulSoup(response.content, 'html.parser')

            # Extract recipe data
            recipe_data = {
                'name': self._extract_name(soup),
                'description': self._extract_description(soup),
                'image_url': self._extract_image(soup),
                'prep_time': self._extract_prep_time(soup),
                'cook_time': self._extract_cook_time(soup),
                'servings': self._extract_servings(soup),
                'difficulty': self._extract_difficulty(soup),
                'ingredients': self._extract_ingredients(soup),
                'instructions': self._extract_instructions(soup),
                'nutrition': self._extract_nutrition(soup),
                'tags': self._extract_tags(soup),
                'source_url': url,
            }

            return recipe_data

        except Exception as e:
            raise Exception(f"Failed to scrape Chefkoch recipe: {str(e)}")

    def _extract_name(self, soup: BeautifulSoup) -> str:
        """Extract recipe name"""
        # Try multiple selectors
        name_selectors = [
            ('h1', {'class': 'ds-h2'}),
            ('h1', {'class': 'page-title'}),
            ('h1', {}),
            ('meta', {'property': 'og:title'}),
        ]

        for tag, attrs in name_selectors:
            if tag == 'meta':
                element = soup.find(tag, attrs)
                if element and element.get('content'):
                    return element.get('content').strip()
            else:
                element = soup.find(tag, attrs)
                if element:
                    return element.get_text(strip=True)

        return "Unbenanntes Rezept"

    def _extract_description(self, soup: BeautifulSoup) -> str:
        """Extract recipe description"""
        # Try meta description
        meta_desc = soup.find('meta', {'name': 'description'})
        if meta_desc and meta_desc.get('content'):
            return meta_desc.get('content').strip()

        # Try recipe-text class
        desc = soup.find('div', {'class': 'recipe-text'})
        if desc:
            return desc.get_text(strip=True)

        # Try ds-box class
        desc = soup.find('div', {'class': 'ds-box'})
        if desc:
            text = desc.get_text(strip=True)
            if text and len(text) > 20:
                return text[:500]

        return "Ein leckeres Rezept von Chefkoch.de"

    def _extract_image(self, soup: BeautifulSoup) -> Optional[str]:
        """Extract recipe image URL"""
        # Try Open Graph image
        og_image = soup.find('meta', {'property': 'og:image'})
        if og_image and og_image.get('content'):
            return og_image.get('content')

        # Try recipe image classes
        img_selectors = [
            ('img', {'class': 'ds-image'}),
            ('img', {'class': 'recipe-image'}),
            ('picture', {'class': 'ds-image'}),
        ]

        for tag, attrs in img_selectors:
            element = soup.find(tag, attrs)
            if element:
                if tag == 'picture':
                    img = element.find('img')
                    if img:
                        return img.get('src') or img.get('data-src')
                else:
                    return element.get('src') or element.get('data-src')

        return None

    def _extract_prep_time(self, soup: BeautifulSoup) -> int:
        """Extract preparation time in minutes"""
        # Try to find recipe-preptime
        prep_time = soup.find('span', {'class': 'recipe-preptime'})
        if prep_time:
            text = prep_time.get_text()
            minutes = self._parse_time_to_minutes(text)
            if minutes:
                return minutes

        # Try recipe-info schema
        prep_schema = soup.find('meta', {'itemprop': 'prepTime'})
        if prep_schema and prep_schema.get('content'):
            return self._parse_iso_duration(prep_schema.get('content'))

        # Default to 15 minutes if not found
        return 15

    def _extract_cook_time(self, soup: BeautifulSoup) -> int:
        """Extract cooking time in minutes"""
        # Try to find recipe-cooktime
        cook_time = soup.find('span', {'class': 'recipe-cooktime'})
        if cook_time:
            text = cook_time.get_text()
            minutes = self._parse_time_to_minutes(text)
            if minutes:
                return minutes

        # Try recipe-info schema
        cook_schema = soup.find('meta', {'itemprop': 'cookTime'})
        if cook_schema and cook_schema.get('content'):
            return self._parse_iso_duration(cook_schema.get('content'))

        # Try totalTime and subtract prepTime
        total_schema = soup.find('meta', {'itemprop': 'totalTime'})
        if total_schema and total_schema.get('content'):
            total = self._parse_iso_duration(total_schema.get('content'))
            prep = self._extract_prep_time(soup)
            return max(total - prep, 0)

        # Default to 30 minutes
        return 30

    def _extract_servings(self, soup: BeautifulSoup) -> int:
        """Extract number of servings"""
        # Try recipe-servings
        servings = soup.find('input', {'name': 'servings'})
        if servings and servings.get('value'):
            try:
                return int(servings.get('value'))
            except:
                pass

        # Try schema
        yield_schema = soup.find('meta', {'itemprop': 'recipeYield'})
        if yield_schema and yield_schema.get('content'):
            try:
                # Extract number from text like "4 Portionen"
                match = re.search(r'\d+', yield_schema.get('content'))
                if match:
                    return int(match.group())
            except:
                pass

        # Default to 4 servings
        return 4

    def _extract_difficulty(self, soup: BeautifulSoup) -> str:
        """Extract difficulty level"""
        difficulty_map = {
            'simpel': 'easy',
            'einfach': 'easy',
            'normal': 'medium',
            'mittel': 'medium',
            'pfiffig': 'hard',
            'schwer': 'hard',
        }

        # Try to find difficulty
        diff = soup.find('span', {'class': 'recipe-difficulty'})
        if diff:
            text = diff.get_text(strip=True).lower()
            for key, value in difficulty_map.items():
                if key in text:
                    return value

        return 'medium'

    def _extract_ingredients(self, soup: BeautifulSoup) -> List[Dict]:
        """Extract ingredients list"""
        ingredients = []

        # Try to find ingredients table
        ingredient_tables = soup.find_all('table', {'class': 'ingredients'})

        if not ingredient_tables:
            # Try alternative selector
            ingredient_tables = soup.find_all('table', {'class': 'incredients'})

        for table in ingredient_tables:
            rows = table.find_all('tr')
            for row in rows:
                cells = row.find_all('td')
                if len(cells) >= 2:
                    # First cell is quantity, second is ingredient
                    quantity_cell = cells[0].get_text(strip=True)
                    ingredient_cell = cells[1].get_text(strip=True)

                    # Parse quantity and unit
                    quantity, unit = self._parse_quantity(quantity_cell)

                    if ingredient_cell:
                        ingredients.append({
                            'name': ingredient_cell,
                            'quantity': quantity or '1',
                            'unit': unit or 'Stück',
                        })

        # If no ingredients found, try JSON-LD schema
        if not ingredients:
            ingredients = self._extract_ingredients_from_schema(soup)

        return ingredients

    def _extract_ingredients_from_schema(self, soup: BeautifulSoup) -> List[Dict]:
        """Extract ingredients from JSON-LD schema"""
        ingredients = []

        scripts = soup.find_all('script', {'type': 'application/ld+json'})
        for script in scripts:
            try:
                data = json.loads(script.string)
                if isinstance(data, dict) and data.get('@type') == 'Recipe':
                    ingredient_list = data.get('recipeIngredient', [])
                    for ing_text in ingredient_list:
                        quantity, unit = self._parse_quantity(ing_text)
                        name = re.sub(r'^\d+[\s,\.]*[a-zA-Z]*\s*', '', ing_text).strip()

                        ingredients.append({
                            'name': name or ing_text,
                            'quantity': quantity or '1',
                            'unit': unit or 'Stück',
                        })
            except:
                continue

        return ingredients

    def _extract_instructions(self, soup: BeautifulSoup) -> List[str]:
        """Extract recipe instructions"""
        instructions = []

        # Primary method: Find instruction-row divs (Chefkoch's new layout)
        instruction_rows = soup.find_all('div', {'class': 'instruction-row'})
        if instruction_rows:
            for row in instruction_rows:
                # Get all text content, skip the step number
                text = row.get_text(strip=True)
                # Remove leading number if present (e.g., "1Das Hack..." -> "Das Hack...")
                text = re.sub(r'^\d+', '', text).strip()
                if text and len(text) > 10:
                    instructions.append(text)

        # Fallback 1: Find h2 "Zubereitung" and get following paragraphs
        if not instructions:
            zubereitung_h2 = soup.find('h2', string=lambda t: t and 'Zubereitung' in t)
            if zubereitung_h2:
                for sibling in zubereitung_h2.next_siblings:
                    if sibling.name in ['p', 'div']:
                        text = sibling.get_text(strip=True)
                        if text and len(text) > 10 and not text.startswith('Min'):
                            # Skip time information
                            instructions.append(text)
                            if len(instructions) >= 10:  # Limit to reasonable number
                                break

        # Fallback 2: Try JSON-LD schema
        if not instructions:
            scripts = soup.find_all('script', {'type': 'application/ld+json'})
            for script in scripts:
                try:
                    data = json.loads(script.string)
                    if isinstance(data, dict) and data.get('@type') == 'Recipe':
                        inst_list = data.get('recipeInstructions', [])
                        if isinstance(inst_list, list):
                            for step in inst_list:
                                if isinstance(step, dict):
                                    text = step.get('text', '')
                                elif isinstance(step, str):
                                    text = step
                                else:
                                    continue

                                if text and text.strip():
                                    instructions.append(text.strip())
                        elif isinstance(inst_list, str):
                            # Sometimes it's a single string
                            instructions.append(inst_list.strip())
                except:
                    continue

        # Fallback 3: Traditional method
        if not instructions:
            inst_div = soup.find('div', {'id': 'rezept-zubereitung'})
            if inst_div:
                paragraphs = inst_div.find_all(['p', 'li'])
                for p in paragraphs:
                    text = p.get_text(strip=True)
                    if text and len(text) > 10:
                        instructions.append(text)

        # If still no instructions, return placeholder
        if not instructions:
            instructions = ["Zubereitung laut Originalrezept auf Chefkoch.de"]

        return instructions

    def _extract_nutrition(self, soup: BeautifulSoup) -> Optional[Dict]:
        """Extract nutrition information"""
        nutrition = {}

        # Try to find nutrition table
        nut_table = soup.find('table', {'class': 'nutrition'})
        if nut_table:
            rows = nut_table.find_all('tr')
            for row in rows:
                cells = row.find_all('td')
                if len(cells) >= 2:
                    label = cells[0].get_text(strip=True).lower()
                    value = cells[1].get_text(strip=True)

                    # Extract numeric value
                    match = re.search(r'(\d+[,\.]?\d*)', value)
                    if match:
                        num_value = float(match.group(1).replace(',', '.'))

                        if 'kalorien' in label or 'kcal' in label:
                            nutrition['calories'] = int(num_value)
                        elif 'eiweiß' in label or 'protein' in label:
                            nutrition['protein'] = num_value
                        elif 'kohlenhydrat' in label or 'carbs' in label:
                            nutrition['carbs'] = num_value
                        elif 'fett' in label or 'fat' in label:
                            nutrition['fat'] = num_value
                        elif 'ballast' in label or 'fiber' in label:
                            nutrition['fiber'] = num_value

        # Try JSON-LD schema
        if not nutrition:
            scripts = soup.find_all('script', {'type': 'application/ld+json'})
            for script in scripts:
                try:
                    data = json.loads(script.string)
                    if isinstance(data, dict) and data.get('@type') == 'Recipe':
                        nut_data = data.get('nutrition', {})
                        if nut_data:
                            if 'calories' in nut_data:
                                nutrition['calories'] = int(float(nut_data['calories']))
                            if 'proteinContent' in nut_data:
                                nutrition['protein'] = float(nut_data['proteinContent'])
                            if 'carbohydrateContent' in nut_data:
                                nutrition['carbs'] = float(nut_data['carbohydrateContent'])
                            if 'fatContent' in nut_data:
                                nutrition['fat'] = float(nut_data['fatContent'])
                except:
                    continue

        return nutrition if nutrition else None

    def _extract_tags(self, soup: BeautifulSoup) -> List[str]:
        """Extract recipe tags"""
        tags = []

        # Try to find tag links
        tag_links = soup.find_all('a', {'class': 'ds-tag'})
        for link in tag_links:
            tag = link.get_text(strip=True)
            if tag:
                tags.append(tag)

        # Limit to 10 tags
        return tags[:10]

    def _parse_quantity(self, text: str) -> tuple:
        """Parse quantity and unit from text like '200 g' or '2 EL'"""
        # Common German units
        units = [
            'kg', 'g', 'mg',
            'l', 'ml', 'dl',
            'EL', 'TL', 'Msp',
            'Prise', 'Stück', 'St',
            'Bund', 'Scheibe', 'Scheiben',
            'Tasse', 'Becher',
            'Dose', 'Dosen',
            'Pkt', 'Packung',
        ]

        # Try to match number and unit
        pattern = r'(\d+[,\./]?\d*)\s*([a-zA-Z]+)?'
        match = re.search(pattern, text)

        if match:
            quantity = match.group(1).replace(',', '.')
            unit = match.group(2) or ''

            # Normalize unit
            if unit in units:
                return quantity, unit
            elif unit:
                return quantity, unit
            else:
                return quantity, 'Stück'

        return None, None

    def _parse_time_to_minutes(self, text: str) -> Optional[int]:
        """Parse time text to minutes"""
        # Extract hours and minutes
        hours = 0
        minutes = 0

        hour_match = re.search(r'(\d+)\s*(?:Std|Stunde|h)', text, re.IGNORECASE)
        if hour_match:
            hours = int(hour_match.group(1))

        min_match = re.search(r'(\d+)\s*(?:Min|Minute|m)', text, re.IGNORECASE)
        if min_match:
            minutes = int(min_match.group(1))

        total = hours * 60 + minutes
        return total if total > 0 else None

    def _parse_iso_duration(self, duration: str) -> int:
        """Parse ISO 8601 duration to minutes (e.g., 'PT30M' -> 30)"""
        try:
            # Format: PT{hours}H{minutes}M or PT{minutes}M
            hours = 0
            minutes = 0

            hour_match = re.search(r'(\d+)H', duration)
            if hour_match:
                hours = int(hour_match.group(1))

            min_match = re.search(r'(\d+)M', duration)
            if min_match:
                minutes = int(min_match.group(1))

            return hours * 60 + minutes
        except:
            return 0


# Test function
if __name__ == '__main__':
    scraper = ChefkochScraper()

    # Test with a Chefkoch URL
    test_url = "https://www.chefkoch.de/rezepte/1234567890/Beispiel-Rezept.html"

    try:
        recipe = scraper.scrape_recipe(test_url)
        print(json.dumps(recipe, indent=2, ensure_ascii=False))
    except Exception as e:
        print(f"Error: {e}")
