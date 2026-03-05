# GMS Backend - Modular Architecture

A modular Node.js/Express backend for the Gym Management System with improved code organization and maintainability.

## 🚀 Features

- **Modular Architecture**: Separated concerns into config, models, services, routes, and middleware
- **Environment Configuration**: Configurable settings via environment variables
- **Error Handling**: Centralized error handling with custom error classes
- **Database Abstraction**: Connection pooling and query abstraction
- **Input Validation**: Request validation middleware
- **Security**: Password hashing, input sanitization
- **Payment Integration**: Stripe payment processing

## 📁 Project Structure

```
GMS_Backend/
├── config/
│   ├── config.js          # Environment configuration
│   └── database.js        # Database connection management
├── middleware/
│   └── common.js          # Common middleware (logging, validation, error handling)
├── models/
│   ├── User.js            # User/registration data models
│   └── Payment.js         # Payment data models
├── routes/
│   ├── auth.js            # Authentication routes (login, registration)
│   └── payment.js         # Payment routes (Stripe integration)
├── services/
│   ├── AuthService.js     # Authentication business logic
│   └── PaymentService.js  # Payment business logic
├── utils/
│   ├── validators.js      # Input validation utilities
│   └── errorHandler.js    # Error handling utilities
├── .env.example           # Environment variables template
├── package.json
├── server.js              # Main application entry point
└── server_old.js          # Original monolithic server (backup)
```

## 🛠 Installation & Setup

1. **Install Dependencies**
   ```bash
   npm install
   ```

2. **Environment Configuration**
   ```bash
   cp .env.example .env
   # Edit .env with your actual configuration values
   ```

3. **Start the Server**
   ```bash
   npm start
   ```

## 🔧 Configuration

The application uses environment variables for configuration. Key settings include:

- **Database**: MySQL connection parameters
- **Stripe**: Payment processing configuration
- **Security**: Password requirements and bcrypt settings
- **Server**: Port and environment settings

## 📡 API Endpoints

### Authentication
- `GET /api/health` - Health check
- `POST /api/registration` - User registration
- `POST /api/login` - User login
- `GET /api/registrations` - Get all registrations (admin)
- `PUT /api/registrations/:id/approve` - Approve registration (admin)

### Payments
- `POST /api/create-payment-intent` - Create Stripe payment intent
- `POST /api/record-payment` - Record successful payment
- `POST /api/record-cash-payment` - Record cash payment
- `GET /api/payment-status/:applicationId` - Check payment status

## 🏗 Architecture Benefits

### Before (Monolithic)
- Single 586-line file
- Mixed concerns (routes, database, business logic)
- Hard-coded configuration
- Difficult to test and maintain

### After (Modular)
- **Separation of Concerns**: Each module has a single responsibility
- **Testability**: Individual components can be unit tested
- **Maintainability**: Changes are localized to specific modules
- **Scalability**: Easy to add new features without affecting existing code
- **Configuration Management**: Environment-based configuration
- **Error Handling**: Centralized and consistent error management
- **Code Reusability**: Shared utilities and services

## 🔒 Security Improvements

- Environment variable configuration (no hard-coded secrets)
- Input validation middleware
- Proper password hashing with bcrypt
- SQL injection prevention with parameterized queries
- CORS configuration
- Error message sanitization

## 🚀 Performance Optimizations

- Database connection pooling
- Async/await throughout (no callback hell)
- Centralized database query management
- Efficient error handling without try-catch repetition

## 🧪 Testing

The modular structure enables better testing:

```javascript
// Example: Testing AuthService independently
const AuthService = require('./services/AuthService');

// Unit test registration logic
describe('AuthService.register', () => {
  it('should create a new user registration', async () => {
    // Test implementation
  });
});
```

## 📝 Migration Notes

- Original `server.js` backed up as `server_old.js`
- All functionality preserved and improved
- API endpoints remain unchanged for frontend compatibility
- Database schema unchanged

## 🤝 Contributing

1. Follow the modular structure
2. Add new features in appropriate modules
3. Update configuration for new environment variables
4. Add proper error handling
5. Test thoroughly before committing

---

**Maintained Functionality**: All original features work exactly as before, but with improved code organization, security, and maintainability.