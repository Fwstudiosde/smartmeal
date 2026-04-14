"""
Push Notification Service for SmartMeal

Sends deal alerts to users via Firebase Cloud Messaging (FCM).
Requires FIREBASE_CREDENTIALS env var pointing to a service account JSON,
or FIREBASE_CREDENTIALS_JSON containing the JSON directly.
"""

import os
import json
import logging
from typing import List, Dict, Optional

logger = logging.getLogger(__name__)

# Firebase Admin SDK - optional import
try:
    import firebase_admin
    from firebase_admin import credentials, messaging
    FIREBASE_AVAILABLE = True
except ImportError:
    FIREBASE_AVAILABLE = False
    logger.warning("firebase-admin not installed. Push notifications disabled.")


def _initialize_firebase():
    """Initialize Firebase Admin SDK if not already done"""
    if not FIREBASE_AVAILABLE:
        return False

    if firebase_admin._apps:
        return True

    try:
        # Try JSON string from env var first
        creds_json = os.getenv('FIREBASE_CREDENTIALS_JSON')
        if creds_json:
            creds_dict = json.loads(creds_json)
            cred = credentials.Certificate(creds_dict)
            firebase_admin.initialize_app(cred)
            logger.info("Firebase initialized from FIREBASE_CREDENTIALS_JSON")
            return True

        # Try file path
        creds_path = os.getenv('FIREBASE_CREDENTIALS')
        if creds_path and os.path.exists(creds_path):
            cred = credentials.Certificate(creds_path)
            firebase_admin.initialize_app(cred)
            logger.info(f"Firebase initialized from {creds_path}")
            return True

        logger.warning("No Firebase credentials found. Push notifications disabled.")
        return False

    except Exception as e:
        logger.error(f"Error initializing Firebase: {e}")
        return False


async def send_deal_alerts(new_deals: List[Dict], supabase_client) -> int:
    """
    Send push notifications about new deals to subscribed users.

    Uses FCM topics: deals_lidl, deals_aldi, deals_rewe, etc.
    Users subscribe to topics based on their preferred supermarkets.

    Args:
        new_deals: List of new deal dictionaries
        supabase_client: Supabase client for querying user preferences

    Returns:
        Number of notifications sent
    """
    if not _initialize_firebase():
        return 0

    if not new_deals:
        return 0

    # Group deals by store
    deals_by_store: Dict[str, List[Dict]] = {}
    for deal in new_deals:
        store = deal.get('store_name', 'Unknown')
        if store not in deals_by_store:
            deals_by_store[store] = []
        deals_by_store[store].append(deal)

    sent_count = 0

    for store_name, store_deals in deals_by_store.items():
        try:
            # Create notification content
            top_deals = store_deals[:3]
            deal_names = ', '.join(d.get('product_name', '?') for d in top_deals)

            title = f"Neue Angebote bei {store_name}!"
            body = f"{len(store_deals)} neue Angebote: {deal_names}"
            if len(store_deals) > 3:
                body += f" und {len(store_deals) - 3} weitere"

            # Send to FCM topic
            topic = f"deals_{store_name.lower().replace(' ', '_')}"

            message = messaging.Message(
                notification=messaging.Notification(
                    title=title,
                    body=body,
                ),
                data={
                    'type': 'deal_alert',
                    'store': store_name,
                    'deal_count': str(len(store_deals)),
                },
                topic=topic,
            )

            response = messaging.send(message)
            logger.info(f"Notification sent to topic '{topic}': {response}")
            sent_count += 1

        except Exception as e:
            logger.error(f"Error sending notification for {store_name}: {e}")

    return sent_count
