package com.bsg.payment;

import org.apache.hc.client5.http.classic.methods.HttpPost;
import org.apache.hc.client5.http.impl.classic.CloseableHttpClient;
import org.apache.hc.client5.http.impl.classic.HttpClients;
import org.apache.hc.core5.http.io.entity.StringEntity;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.net.InetSocketAddress;
import java.time.Instant;
import java.util.UUID;
import com.sun.net.httpserver.HttpServer;
import com.sun.net.httpserver.HttpHandler;
import com.sun.net.httpserver.HttpExchange;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class PaymentApp {
    private static final Logger logger = LoggerFactory.getLogger(PaymentApp.class);

    public static void main(String[] args) throws Exception {
        // Start HTTP server for health check
        HttpServer server = HttpServer.create(new InetSocketAddress(80), 0);
        server.createContext("/health", new HealthHandler());
        server.setExecutor(null); // creates a default executor
        server.start();
        logger.info("Health check server started on port 80");

        String gethUrl = System.getenv().getOrDefault("GETH_URL", "http://localhost:8545");
        String txValue = "100";
        String transactionId = UUID.randomUUID().toString();

        String payload = "{ \"jsonrpc\":\"2.0\", \"method\":\"eth_blockNumber\", \"params\":[], \"id\":1 }";

        try (CloseableHttpClient client = HttpClients.createDefault()) {
            HttpPost post = new HttpPost(gethUrl);
            post.setHeader("Content-Type", "application/json");
            post.setEntity(new StringEntity(payload));
            client.execute(post, response -> {
                BufferedReader rd = new BufferedReader(new InputStreamReader(response.getEntity().getContent()));
                StringBuilder result = new StringBuilder();
                String line;
                while ((line = rd.readLine()) != null) {
                    result.append(line);
                }
                logTransaction(transactionId, txValue, result.toString());
                return null;
            });
        } catch (Exception e) {
            logger.error("Error contacting Geth: {}", e.getMessage());
        }
    }

    private static void logTransaction(String id, String value, String result) {
        String logEntry = String.format("%s | TxID: %s | Value: %s | Result: %s",
                Instant.now().toString(), id, value, result);
        logger.info(logEntry);
        // For production, push to CloudWatch and put relevant audit to S3 (via Lambda or sidecar)
    }

    static class HealthHandler implements HttpHandler {
        @Override
        public void handle(HttpExchange t) {
            try {
                String response = "OK";
                t.sendResponseHeaders(200, response.length());
                OutputStream os = t.getResponseBody();
                os.write(response.getBytes());
                os.close();
            } catch (Exception e) {
                // ignore
            }
        }
    }
}
