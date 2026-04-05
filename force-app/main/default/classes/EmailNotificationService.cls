public with sharing class EmailNotificationService {
    public static void sendLowStockAlerts(List<Vehicle__c> vehicles) {
        if (vehicles == null || vehicles.isEmpty()) {
            return;
        }

        String currentUserEmail = [SELECT Email FROM User WHERE Id = :UserInfo.getUserId()].Email;
        if (String.isBlank(currentUserEmail)) {
            return;
        }

        List<String> bodyLines = new List<String>();
        for (Vehicle__c vehicleRecord : vehicles) {
            bodyLines.add(
                vehicleRecord.Name + ' | Stock: ' + String.valueOf(vehicleRecord.Available_Stock__c)
                + ' | Threshold: ' + String.valueOf(vehicleRecord.Reorder_Threshold__c)
            );
        }

        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(new String[] { currentUserEmail });
        email.setSubject('WhatNext Vision Motors low stock alert');
        email.setPlainTextBody(
            'The following vehicles are at or below their reorder threshold:\n\n'
            + String.join(bodyLines, '\n')
        );

        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
    }

    public static void sendTestDriveReminders(List<Test_Drive__c> testDrives) {
        if (testDrives == null || testDrives.isEmpty()) {
            return;
        }

        List<Messaging.SingleEmailMessage> outboundEmails = new List<Messaging.SingleEmailMessage>();
        for (Test_Drive__c testDriveRecord : testDrives) {
            if (String.isBlank(testDriveRecord.Customer_Email__c)) {
                continue;
            }

            String customerName = String.isBlank(testDriveRecord.Customer_Name__c)
                ? 'Customer'
                : testDriveRecord.Customer_Name__c;
            String vehicleName = testDriveRecord.Vehicle__r == null
                ? 'your selected vehicle'
                : testDriveRecord.Vehicle__r.Name;
            String dealerName = testDriveRecord.Dealer__r == null
                ? 'your assigned dealer'
                : testDriveRecord.Dealer__r.Name;
            String scheduleText = testDriveRecord.Scheduled_Date_Time__c == null
                ? 'the scheduled time'
                : testDriveRecord.Scheduled_Date_Time__c.format('dd MMM yyyy hh:mm a');

            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new String[] { testDriveRecord.Customer_Email__c });
            email.setSubject('Reminder: your WhatNext Vision Motors test drive');
            email.setPlainTextBody(
                'Hello ' + customerName + ',\n\n'
                + 'This is a reminder for your upcoming test drive for '
                + vehicleName + ' with ' + dealerName + ' on ' + scheduleText + '.\n\n'
                + 'Thank you,\nWhatNext Vision Motors'
            );
            outboundEmails.add(email);
        }

        sendEmailInChunks(outboundEmails);
    }

    public static void sendOrderStatusNotifications(
        List<Customer_Order__c> orders,
        Map<Id, Customer_Order__c> oldMap
    ) {
        if (orders == null || orders.isEmpty()) {
            return;
        }

        Set<Id> orderIdsToNotify = new Set<Id>();
        for (Customer_Order__c orderRecord : orders) {
            if (shouldSendOrderStatusNotification(orderRecord, oldMap)) {
                orderIdsToNotify.add(orderRecord.Id);
            }
        }

        if (orderIdsToNotify.isEmpty()) {
            return;
        }

        List<Customer_Order__c> ordersToNotify = [
            SELECT Id, Customer_Name__c, Customer_Email__c, Order_Status__c, Requested_Delivery_Date__c,
                Vehicle__r.Name, Dealer__r.Name
            FROM Customer_Order__c
            WHERE Id IN :orderIdsToNotify
        ];

        List<Messaging.SingleEmailMessage> outboundEmails = new List<Messaging.SingleEmailMessage>();
        for (Customer_Order__c orderRecord : ordersToNotify) {
            if (String.isBlank(orderRecord.Customer_Email__c)) {
                continue;
            }

            String customerName = String.isBlank(orderRecord.Customer_Name__c)
                ? 'Customer'
                : orderRecord.Customer_Name__c;
            String vehicleName = orderRecord.Vehicle__r == null ? 'your selected vehicle' : orderRecord.Vehicle__r.Name;
            String dealerName = orderRecord.Dealer__r == null ? 'the assigned dealer' : orderRecord.Dealer__r.Name;
            String deliveryDateText = orderRecord.Requested_Delivery_Date__c == null
                ? 'your requested date'
                : orderRecord.Requested_Delivery_Date__c.format();

            String body = orderRecord.Order_Status__c == 'Confirmed'
                ? 'Hello ' + customerName + ',\n\n'
                    + 'Your order for ' + vehicleName + ' has been confirmed and assigned to '
                    + dealerName + '. Requested delivery date: ' + deliveryDateText + '.\n\n'
                    + 'Thank you,\nWhatNext Vision Motors'
                : 'Hello ' + customerName + ',\n\n'
                    + 'Your order for ' + vehicleName + ' is currently pending due to stock availability. '
                    + 'We will update you once inventory is ready through ' + dealerName + '.\n\n'
                    + 'Thank you,\nWhatNext Vision Motors';

            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new String[] { orderRecord.Customer_Email__c });
            email.setSubject('WhatNext Vision Motors order update: ' + orderRecord.Order_Status__c);
            email.setPlainTextBody(body);
            outboundEmails.add(email);
        }

        sendEmailInChunks(outboundEmails);
    }

    private static Boolean shouldSendOrderStatusNotification(
        Customer_Order__c newOrder,
        Map<Id, Customer_Order__c> oldMap
    ) {
        if (newOrder == null || String.isBlank(newOrder.Customer_Email__c)) {
            return false;
        }

        if (newOrder.Order_Status__c != 'Confirmed' && newOrder.Order_Status__c != 'Pending') {
            return false;
        }

        if (oldMap == null || !oldMap.containsKey(newOrder.Id)) {
            return true;
        }

        return oldMap.get(newOrder.Id).Order_Status__c != newOrder.Order_Status__c;
    }

    private static void sendEmailInChunks(List<Messaging.SingleEmailMessage> outboundEmails) {
        if (outboundEmails == null || outboundEmails.isEmpty()) {
            return;
        }

        List<Messaging.SingleEmailMessage> emailChunk = new List<Messaging.SingleEmailMessage>();
        for (Messaging.SingleEmailMessage outboundEmail : outboundEmails) {
            emailChunk.add(outboundEmail);
            if (emailChunk.size() == 10) {
                Messaging.sendEmail(emailChunk);
                emailChunk.clear();
            }
        }

        if (!emailChunk.isEmpty()) {
            Messaging.sendEmail(emailChunk);
        }
    }
}
