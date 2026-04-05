public with sharing class DealerAssignmentService {
    public static void assignNearestDealers(List<Customer_Order__c> orders) {
        if (orders == null || orders.isEmpty()) {
            return;
        }

        List<Customer_Order__c> candidateOrders = new List<Customer_Order__c>();
        for (Customer_Order__c orderRecord : orders) {
            if (orderRecord.Vehicle__c != null) {
                candidateOrders.add(orderRecord);
            }
        }

        if (candidateOrders.isEmpty()) {
            return;
        }

        List<Dealer__c> dealers = [
            SELECT Id, Name, City__c, State__c, Postal_Code__c, Latitude__c, Longitude__c
            FROM Dealer__c
        ];

        if (dealers.isEmpty()) {
            for (Customer_Order__c orderRecord : candidateOrders) {
                orderRecord.addError('Create at least one dealer before submitting customer orders.');
            }
            return;
        }

        for (Customer_Order__c orderRecord : candidateOrders) {
            Dealer__c bestDealer = getBestDealer(orderRecord, dealers);
            if (bestDealer != null) {
                orderRecord.Dealer__c = bestDealer.Id;
            }
        }
    }

    @TestVisible
    private static Dealer__c getBestDealer(Customer_Order__c orderRecord, List<Dealer__c> dealers) {
        if (hasCoordinates(orderRecord.Customer_Latitude__c, orderRecord.Customer_Longitude__c)) {
            Dealer__c nearestDealer;
            Decimal nearestDistance;

            for (Dealer__c dealerRecord : dealers) {
                if (!hasCoordinates(dealerRecord.Latitude__c, dealerRecord.Longitude__c)) {
                    continue;
                }

                Decimal distance = calculateDistanceKm(
                    orderRecord.Customer_Latitude__c,
                    orderRecord.Customer_Longitude__c,
                    dealerRecord.Latitude__c,
                    dealerRecord.Longitude__c
                );

                if (nearestDealer == null || distance < nearestDistance) {
                    nearestDealer = dealerRecord;
                    nearestDistance = distance;
                }
            }

            if (nearestDealer != null) {
                return nearestDealer;
            }
        }

        for (Dealer__c dealerRecord : dealers) {
            if (!String.isBlank(orderRecord.Customer_Postal_Code__c)
                && orderRecord.Customer_Postal_Code__c == dealerRecord.Postal_Code__c) {
                return dealerRecord;
            }
        }

        for (Dealer__c dealerRecord : dealers) {
            if (!String.isBlank(orderRecord.Customer_State__c)
                && orderRecord.Customer_State__c == dealerRecord.State__c) {
                return dealerRecord;
            }
        }

        return dealers[0];
    }

    @TestVisible
    private static Boolean hasCoordinates(Decimal latitude, Decimal longitude) {
        return latitude != null && longitude != null;
    }

    @TestVisible
    private static Decimal calculateDistanceKm(
        Decimal startLatitude,
        Decimal startLongitude,
        Decimal endLatitude,
        Decimal endLongitude
    ) {
        Double earthRadiusKm = 6371.0;
        Double latDistance = toRadians(endLatitude - startLatitude);
        Double lonDistance = toRadians(endLongitude - startLongitude);
        Double originLatitude = toRadians(startLatitude);
        Double destinationLatitude = toRadians(endLatitude);

        Double haversine = Math.sin(latDistance / 2) * Math.sin(latDistance / 2)
            + Math.cos(originLatitude) * Math.cos(destinationLatitude)
            * Math.sin(lonDistance / 2) * Math.sin(lonDistance / 2);
        Double centralAngle = 2 * Math.atan2(Math.sqrt(haversine), Math.sqrt(1 - haversine));
        Double distance = earthRadiusKm * centralAngle;

        return Decimal.valueOf(String.valueOf(distance)).setScale(2);
    }

    private static Double toRadians(Decimal degreesValue) {
        return Double.valueOf(String.valueOf(degreesValue)) * Math.PI() / 180;
    }
}
