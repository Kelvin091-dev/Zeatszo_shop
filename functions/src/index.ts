import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

admin.initializeApp();

export const sendOrderNotification = functions.firestore
  .document('orders/{orderId}')
  .onCreate(async (snap, context) => {
    const orderData = snap.data();
    const shopId = orderData.shopId;

    try {
      const shopDoc = await admin.firestore().collection('shops').doc(shopId).get();
      if (!shopDoc.exists) {
        console.log('Shop not found:', shopId);
        return;
      }

      const shopData = shopDoc.data();
      const ownerId = shopData?.ownerId;

      if (!ownerId) {
        console.log('No owner ID for shop:', shopId);
        return;
      }

      const userDoc = await admin.firestore().collection('users').doc(ownerId).get();
      if (!userDoc.exists) {
        console.log('User not found:', ownerId);
        return;
      }

      const userData = userDoc.data();
      const fcmToken = userData?.fcmToken;

      if (!fcmToken) {
        console.log('No FCM token for user:', ownerId);
        return;
      }

      const message = {
        notification: {
          title: 'New Order Received! 🎉',
          body: `Order from ${orderData.customerName} - $${orderData.totalAmount.toFixed(2)}`,
        },
        data: {
          orderId: context.params.orderId,
          type: 'new_order',
          customerName: orderData.customerName,
          totalAmount: orderData.totalAmount.toString(),
        },
        token: fcmToken,
      };

      await admin.messaging().send(message);
      console.log('Notification sent successfully for order:', context.params.orderId);
    } catch (error) {
      console.error('Error sending notification:', error);
    }
  });

export const sendOrderStatusUpdate = functions.firestore
  .document('orders/{orderId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    if (before.status === after.status) {
      return;
    }

    const orderData = after;
    const customerId = orderData.customerId;

    try {
      const userDoc = await admin.firestore().collection('users').doc(customerId).get();
      if (!userDoc.exists) {
        console.log('Customer not found:', customerId);
        return;
      }

      const userData = userDoc.data();
      const fcmToken = userData?.fcmToken;

      if (!fcmToken) {
        console.log('No FCM token for customer:', customerId);
        return;
      }

      const statusMessages: { [key: string]: string } = {
        confirmed: 'Your order has been confirmed! ✅',
        preparing: 'Your order is being prepared 👨‍🍳',
        ready: 'Your order is ready for pickup! 🎉',
        completed: 'Order completed. Thank you! 🙏',
        cancelled: 'Your order has been cancelled',
      };

      const message = {
        notification: {
          title: 'Order Status Update',
          body: statusMessages[after.status] || `Order status: ${after.status}`,
        },
        data: {
          orderId: context.params.orderId,
          type: 'status_update',
          status: after.status,
        },
        token: fcmToken,
      };

      await admin.messaging().send(message);
      console.log('Status update notification sent for order:', context.params.orderId);
    } catch (error) {
      console.error('Error sending status update notification:', error);
    }
  });

export const updateRevenueStats = functions.firestore
  .document('orders/{orderId}')
  .onWrite(async (change, context) => {
    const orderData = change.after.exists ? change.after.data() : null;
    
    if (!orderData || orderData.status !== 'completed') {
      return;
    }

    const shopId = orderData.shopId;
    const statsRef = admin.firestore().collection('shops').doc(shopId).collection('stats').doc('revenue');

    try {
      await admin.firestore().runTransaction(async (transaction) => {
        const statsDoc = await transaction.get(statsRef);
        
        if (!statsDoc.exists) {
          transaction.set(statsRef, {
            totalRevenue: orderData.totalAmount,
            totalOrders: 1,
            lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
          });
        } else {
          const currentStats = statsDoc.data();
          transaction.update(statsRef, {
            totalRevenue: (currentStats?.totalRevenue || 0) + orderData.totalAmount,
            totalOrders: (currentStats?.totalOrders || 0) + 1,
            lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
          });
        }
      });

      console.log('Revenue stats updated for shop:', shopId);
    } catch (error) {
      console.error('Error updating revenue stats:', error);
    }
  });
