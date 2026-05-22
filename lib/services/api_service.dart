import 'auth_service.dart';
import 'ticket_service.dart';

class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  final AuthService auth = AuthService();
  final TicketService tickets = TicketService();
}
