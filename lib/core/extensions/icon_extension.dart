import 'package:flutter/material.dart';

extension IconNameExtension on String {
  IconData toIconData() {
    switch (this) {
      case 'casino':
        return Icons.casino;
      case 'pie_chart':
        return Icons.pie_chart;
      case 'savings':
        return Icons.savings;
      case 'trending_up':
        return Icons.trending_up;
      case 'shield':
        return Icons.shield;
      case 'school':
        return Icons.school;
      case 'balance':
        return Icons.balance;
      case 'menu_book':
        return Icons.menu_book;
      case 'show_chart':
        return Icons.show_chart;
      case 'account_balance':
        return Icons.account_balance;
      case 'attach_money':
        return Icons.attach_money;
      case 'diamond':
        return Icons.diamond;
      case 'store':
        return Icons.store;
      case 'sports_esports':
        return Icons.sports_esports;
      case 'emoji_events':
        return Icons.emoji_events;
      case 'leaderboard':
        return Icons.leaderboard;
      case 'euro':
        return Icons.euro;
      case 'business':
        return Icons.business;
      case 'apartment':
        return Icons.apartment;
      case 'public':
        return Icons.public;
      case 'person':
        return Icons.person;
      case 'self_improvement':
        return Icons.self_improvement;
      case 'autorenew':
        return Icons.autorenew;
      default:
        return Icons.help_outline;
    }
  }
}
