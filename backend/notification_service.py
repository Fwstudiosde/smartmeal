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
                android=messaging.AndroidConfig(
                    priority='high',
                    notification=messaging.AndroidNotification(
                        channel_id='deal_alerts',
                    ),
                ),
                apns=messaging.APNSConfig(
                    payload=messaging.APNSPayload(
                        aps=messaging.Aps(
                            sound='default',
                            badge=1,
                        ),
                    ),
                ),
            )

            response = messaging.send(message)
            logger.info(f"Notification sent to topic '{topic}': {response}")
            sent_count += 1

        except Exception as e:
            logger.error(f"Error sending notification for {store_name}: {e}")

    return sent_count


async def send_to_topic(topic: str, title: str, body: str, data: Optional[Dict[str, str]] = None) -> str:
    """
    Send a push notification to a specific FCM topic.

    Args:
        topic: FCM topic name (e.g. 'deals_lidl', 'all_users')
        title: Notification title
        body: Notification body text
        data: Optional data payload

    Returns:
        FCM response message ID
    """
    if not _initialize_firebase():
        raise RuntimeError("Firebase not initialized")

    message = messaging.Message(
        notification=messaging.Notification(title=title, body=body),
        data=data or {},
        topic=topic,
        android=messaging.AndroidConfig(
            priority='high',
            notification=messaging.AndroidNotification(channel_id='deal_alerts'),
        ),
        apns=messaging.APNSConfig(
            payload=messaging.APNSPayload(
                aps=messaging.Aps(sound='default', badge=1),
            ),
        ),
    )

    response = messaging.send(message)
    logger.info(f"Notification sent to topic '{topic}': {response}")
    return response


async def send_to_tokens(tokens: List[str], title: str, body: str, data: Optional[Dict[str, str]] = None) -> Dict:
    """
    Send a push notification to specific device tokens.

    Args:
        tokens: List of FCM device tokens
        title: Notification title
        body: Notification body text
        data: Optional data payload

    Returns:
        Dict with success_count, failure_count, and failed_tokens
    """
    if not _initialize_firebase():
        raise RuntimeError("Firebase not initialized")

    if not tokens:
        return {"success_count": 0, "failure_count": 0, "failed_tokens": []}

    message = messaging.MulticastMessage(
        notification=messaging.Notification(title=title, body=body),
        data=data or {},
        tokens=tokens,
        android=messaging.AndroidConfig(
            priority='high',
            notification=messaging.AndroidNotification(channel_id='deal_alerts'),
        ),
        apns=messaging.APNSConfig(
            payload=messaging.APNSPayload(
                aps=messaging.Aps(sound='default', badge=1),
            ),
        ),
    )

    response = messaging.send_each_for_multicast(message)

    failed_tokens = []
    for i, send_response in enumerate(response.responses):
        if not send_response.success:
            failed_tokens.append(tokens[i])
            logger.warning(f"Failed to send to token {tokens[i][:20]}...: {send_response.exception}")

    logger.info(f"Multicast: {response.success_count} success, {response.failure_count} failed")

    return {
        "success_count": response.success_count,
        "failure_count": response.failure_count,
        "failed_tokens": failed_tokens,
    }


async def send_to_all_users(title: str, body: str, data: Optional[Dict[str, str]] = None) -> Dict:
    """
    Send a push notification to all users with registered FCM tokens via Supabase.

    Args:
        title: Notification title
        body: Notification body text
        data: Optional data payload

    Returns:
        Dict with success_count, failure_count
    """
    try:
        from supabase_client import SupabaseClient
        db = SupabaseClient()

        # Fetch all FCM tokens from user_profiles
        result = db.client.table('user_profiles').select('fcm_token').not_.is_('fcm_token', 'null').execute()
        tokens = [row['fcm_token'] for row in result.data if row.get('fcm_token')]

        if not tokens:
            logger.info("No FCM tokens found in user_profiles")
            return {"success_count": 0, "failure_count": 0, "total_tokens": 0}

        logger.info(f"Sending notification to {len(tokens)} devices")
        result = await send_to_tokens(tokens, title, body, data)
        result["total_tokens"] = len(tokens)
        return result

    except Exception as e:
        logger.error(f"Error sending to all users: {e}")
        raise
