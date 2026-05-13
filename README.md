# AMS UP - Academic Management System

A comprehensive university management system designed for Administrators, Teachers, and Students.

## Tech Stack
- **Frontend:** Flutter (Mobile App) with GetX for State Management.
- **Backend:** Go (Golang) for fast and scalable RESTful APIs (following Gem's architecture).
- **Database:** MySQL for the relational database.
- **Push Notification:** Firebase Cloud Messaging (FCM).

## Project Structure (Frontend)
This project follows the GetX Pattern folder structure:
- `lib/app/modules/`: Contains application modules categorized by user roles (admins, students, teachers) and features (booking, evaluation, etc.).
- `lib/app/data/models/`: Data models corresponding to the Database Schema.
- `lib/app/services/`: Background and third-party services like `fcm_service.dart` for Notifications.
