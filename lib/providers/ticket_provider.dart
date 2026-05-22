import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../services/ticket_service.dart';

class TicketProvider extends ChangeNotifier {
  TicketService get tickets => ApiService.instance.tickets;
}
