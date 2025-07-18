# "Healthy Summer" - Full-Stack Wellness Application

**Course**: Summer 2025 Go + Flutter Course  
**Instructor**: Timur Harin  
**Grade**: Automatic A (upon successful completion + technical interview)

---

## 🛠 Tech Stack

- **Backend**: Go (Gin framework)  
- **Frontend**: Flutter (Dart)  
- **Database**: PostgreSQL  
- **Real-time**: WebSockets  
- **Containerization**: Docker  
- **CI/CD**: GitHub Actions  
- **Deployment**:
  - **Backend & Database**: Render.com  
  - **Frontend**: GitHub Pages
- **Authentication**: JWT  

---

## 🎯 Project Overview

Comprehensive **"Healthy Summer"** wellness application that helps users track their summer health activities, nutrition, fitness goals, and social wellness. This project will demonstrate mastery of all course concepts through a real-world, production-ready application.

---

## 👥 Core Features & User Stories

### 1. Activity Tracking System

#### Use Case: Daily Workout Logging
**User Story**: As a fitness enthusiast, I want to log my daily workouts so that I can track my progress and maintain consistency.

**Acceptance Criteria**:
- User can add new activities (running, swimming, cycling, yoga, etc.)
- Each activity includes: type, duration, intensity, calories burned, location
- Activities are timestamped and categorized
- User can view activity history with filtering options
- Real-time calorie calculation based on activity type and duration

#### Use Case: Step Counting Integration
**User Story**: As a user, I want my daily steps to be automatically tracked so I can see my overall activity level.

**Acceptance Criteria**:
- Integration with device step counter (simulated for demo)
- Daily step goals with progress tracking
- Weekly and monthly step summaries
- Achievement badges for step milestones

### 2. Nutrition Management System

#### Use Case: Meal Planning & Logging
**User Story**: As a health-conscious user, I want to plan and log my meals so I can maintain a balanced diet during summer.

**Acceptance Criteria**:
- Add meals with food items, quantities, and nutritional values
- Search food database with nutritional information
- Daily calorie tracking with goal setting
- Water intake tracking with reminders
- Weekly nutrition reports and insights

#### Use Case: Water Intake Tracking
**User Story**: As a user, I want to track my daily water intake so I can stay hydrated during hot summer days.

**Acceptance Criteria**:
- Log water consumption with timestamps
- Daily water intake goals (customizable)
- Hydration reminders throughout the day
- Weekly hydration reports

### 3. Social Wellness Features

#### Use Case: Friend Connections
**User Story**: As a social user, I want to connect with friends so we can motivate each other and share our health journey.

**Acceptance Criteria**:
- Send and accept friend requests
- View friends' public activity feeds
- Share achievements and milestones
- Private messaging between friends

#### Use Case: Group Challenges
**User Story**: As a competitive user, I want to participate in group challenges so I can stay motivated and have fun with friends.

**Acceptance Criteria**:
- Create and join group challenges
- Challenge types: step count, workout frequency, nutrition goals
- Real-time leaderboards
- Challenge completion rewards and badges

### 4. Progress Analytics & Insights

#### Use Case: Personal Dashboard
**User Story**: As a user, I want to see my health progress in one place so I can understand my patterns and stay motivated.

**Acceptance Criteria**:
- Weekly and monthly activity summaries
- Calorie burn vs. intake charts
- Progress towards fitness goals
- Achievement badges and milestones
- Personalized insights and recommendations

#### Use Case: Goal Setting & Tracking
**User Story**: As a goal-oriented user, I want to set and track health goals so I can measure my progress and celebrate achievements.

**Acceptance Criteria**:
- Set SMART goals (Specific, Measurable, Achievable, Relevant, Time-bound)
- Goal categories: fitness, nutrition, social, wellness
- Progress tracking with visual indicators
- Goal completion celebrations and rewards

### 5. Real-time Features

#### Use Case: Live Activity Feed
**User Story**: As a social user, I want to see my friends' activities in real-time so I can stay connected and motivated.

**Acceptance Criteria**:
- Real-time activity updates from friends
- Live notifications for achievements
- Instant messaging between friends
- Real-time challenge leaderboards

#### Use Case: Push Notifications
**User Story**: As a busy user, I want to receive timely reminders so I don't forget to stay active and hydrated.

**Acceptance Criteria**:
- Hydration reminders throughout the day
- Workout schedule reminders
- Goal milestone notifications
- Friend activity notifications
- Challenge deadline reminders

---

## 🏗 Technical Architecture

### Microservices Design (4 Services)

#### 1. User Service
**Responsibilities**:
- User authentication and authorization
- Profile management
- Friend connections
- Achievement system

**Key Endpoints**:
```
POST   /api/users/register
POST   /api/users/login
GET    /api/users/profile
PUT    /api/users/profile
POST   /api/users/friends/request
GET    /api/users/friends
POST   /api/users/achievements
```

#### 2. Activity Service
**Responsibilities**:
- Activity logging and tracking
- Step counting integration
- Calorie calculations
- Activity analytics

**Key Endpoints**:
```
POST   /api/activities
GET    /api/activities
GET    /api/activities/stats
POST   /api/activities/steps
GET    /api/activities/analytics
```

#### 3. Nutrition Service
**Responsibilities**:
- Meal planning and logging
- Food database management
- Water intake tracking
- Nutrition analytics

**Key Endpoints**:
```
POST   /api/meals
GET    /api/meals
POST   /api/water
GET    /api/nutrition/stats
GET    /api/foods/search
```

#### 4. Social Service
**Responsibilities**:
- Real-time messaging
- Group challenges
- Social feed
- Notifications

**Key Endpoints**:
```
POST   /api/challenges
GET    /api/challenges
POST   /api/messages
GET    /api/messages
GET    /api/feed
```

### Project Setup
```bash
# Clone and setup
git clone https://github.com/your-username/sum25-go-flutter-course.git
cd sum25-go-flutter-course
make setup

# Start development environment
make dev
```
