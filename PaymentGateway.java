/**
 * Payment Gateway Subsystem
 * Language: Java
 * Description: Manages payment verification, transaction authorizations, 
 *              ledger recording, and rollback mechanisms for order checkouts.
 */

import java.util.HashMap;
import java.util.Map;
import java.util.UUID;
import java.time.Instant;

public class PaymentGateway {

    public enum TransactionStatus { PENDING, AUTHORIZED, CAPTURED, FAILED, REFUNDED }

    public static class TransactionRecord {
        private final String transactionId;
        private final String orderId;
        private final double amount;
        private TransactionStatus status;
        private final long timestamp;

        public TransactionRecord(String orderId, double amount) {
            this.transactionId = "TXN-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase();
            this.orderId = orderId;
            this.amount = amount;
            this.status = TransactionStatus.PENDING;
            this.timestamp = Instant.now().getEpochSecond();
        }

        public String getTransactionId() { return transactionId; }
        public String getOrderId() { return orderId; }
        public double getAmount() { return amount; }
        public TransactionStatus getStatus() { return status; }
        public void setStatus(TransactionStatus status) { this.status = status; }

        @Override
        public String toString() {
            return String.format("TxnID: %s | Order: %s | Amount: $%.2f | Status: %s | Timestamp: %d",
                    transactionId, orderId, amount, status, timestamp);
        }
    }

    private final Map<String, TransactionRecord> ledger;
    private double reserveBalance;

    public PaymentGateway(double initialReserve) {
        this.ledger = new HashMap<>();
        this.reserveBalance = initialReserve;
    }

    public synchronized TransactionRecord authorizePayment(String orderId, double amount, String paymentToken) {
        TransactionRecord record = new TransactionRecord(orderId, amount);
        System.out.println("[Java Payment] Processing payment authorization for Order: " + orderId);

        if (paymentToken == null || paymentToken.isEmpty() || paymentToken.startsWith("INVALID")) {
            record.setStatus(TransactionStatus.FAILED);
            ledger.put(record.getTransactionId(), record);
            System.err.println("  [DECLINED] Invalid payment token provided.");
            return record;
        }

        record.setStatus(TransactionStatus.AUTHORIZED);
        ledger.put(record.getTransactionId(), record);
        System.out.println("  [APPROVED] Auth Code: " + record.getTransactionId());
        return record;
    }

    public synchronized boolean capturePayment(String transactionId) {
        TransactionRecord record = ledger.get(transactionId);
        if (record != null && record.getStatus() == TransactionStatus.AUTHORIZED) {
            record.setStatus(TransactionStatus.CAPTURED);
            reserveBalance += record.getAmount();
            System.out.println("[Java Payment] Successfully captured payment of $" + record.getAmount());
            return true;
        }
        return false;
    }

    public synchronized boolean processRefund(String transactionId) {
        TransactionRecord record = ledger.get(transactionId);
        if (record != null && record.getStatus() == TransactionStatus.CAPTURED) {
            record.setStatus(TransactionStatus.REFUNDED);
            reserveBalance -= record.getAmount();
            System.out.println("[Java Payment] Refund processed for Txn: " + transactionId);
            return true;
        }
        return false;
    }

    public void printLedgerSummary() {
        System.out.println("\n================ JAVA PAYMENT LEDGER SUMMARY ================");
        System.out.println("Current Reserve Balance: $" + String.format("%.2f", reserveBalance));
        System.out.println("Total Recorded Transactions: " + ledger.size());
        for (TransactionRecord record : ledger.values()) {
            System.out.println("  " + record);
        }
        System.out.println("=============================================================\n");
    }

    public static void main(String[] args) {
        System.out.println("Initializing Payment Gateway Subsystem...");
        PaymentGateway gateway = new PaymentGateway(10000.00);

        TransactionRecord t1 = gateway.authorizePayment("ORD-891A", 209.48, "TOKEN_VALID_CC");
        if (t1.getStatus() == TransactionStatus.AUTHORIZED) {
            gateway.capturePayment(t1.getTransactionId());
        }

        TransactionRecord t2 = gateway.authorizePayment("ORD-992B", 54.00, "INVALID_TOKEN");
        gateway.printLedgerSummary();
    }
}