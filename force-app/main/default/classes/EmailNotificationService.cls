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

        if (!outboundEmails.isEmpty()) {
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
}
