<%@ page import="java.sql.*" %>
<%@ page import="bank.DatabaseConnection" %> 
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%
response.setHeader("Cache-Control","no-store");
response.setHeader("Pragma","no-cache"); 
response.setHeader("Expires", "0"); // Prevent caching at the proxy server

String account_no = request.getParameter("account_no");

if (account_no == null || account_no.isEmpty()) {
    response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
    out.println("Account number is required.");
    return;
}

try (Connection con = DatabaseConnection.getConnection()) {
    // Start a transaction
    con.setAutoCommit(false);

    try {
        // Delete related transactions
        String deleteTransactionsQuery = "DELETE FROM transaction WHERE account_no = ?";
        try (PreparedStatement deleteTransactionsStmt = con.prepareStatement(deleteTransactionsQuery)) {
            deleteTransactionsStmt.setString(1, account_no);
            deleteTransactionsStmt.executeUpdate();
        }

        // Delete the customer record
        String deleteCustomerQuery = "DELETE FROM customer WHERE account_no = ?";
        try (PreparedStatement deleteCustomerStmt = con.prepareStatement(deleteCustomerQuery)) {
            deleteCustomerStmt.setString(1, account_no);
            int result = deleteCustomerStmt.executeUpdate();
            if (result > 0) {
                // Commit the transaction
                con.commit();
                response.sendRedirect("admin_dashboard.jsp?status=deleteSuccess");
            } else {
                con.rollback();
                out.println("Error in deleting the customer.");
            }
        }
    } catch (SQLException e) {
        // Rollback the transaction in case of an error
        con.rollback();
        e.printStackTrace();
        response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
        out.println("Error occurred while processing the request.");
    } finally {
        con.setAutoCommit(true); // Restore auto-commit mode
    }
} catch (SQLException e) {
    // Log the exception and show an error message
    e.printStackTrace();
    response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
    out.println("Database connection error.");
}
%>
