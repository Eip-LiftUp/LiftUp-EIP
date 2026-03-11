use validator::Validate;

use crate::{
    errors::{AppError, AppResult},
    models::user::{CreateUserRequest, User, LoginRequest, UpdateUserRequest},
    repositories::user::UserRepository,
};

/// Business logic for user management.
pub struct UserService {
    repository: UserRepository,
}

impl UserService {
    pub fn new(repository: UserRepository) -> Self {
        Self { repository }
    }

    /// Validate the request, check for duplicates, then persist the new user.
    pub async fn create_user(&self, req: CreateUserRequest) -> AppResult<User> {
        // 1. Validate input fields via the `validator` crate
        req.validate()
            .map_err(|e| AppError::Validation(e.to_string()))?;

        // 2. Check email uniqueness
        if self.repository.email_exists(&req.email).await? {
            return Err(AppError::Conflict(format!(
                "Email '{}' is already registered.",
                req.email
            )));
        }

        // 3. Hash the password
        let password_hash = bcrypt::hash(&req.password, bcrypt::DEFAULT_COST)
            .map_err(|e| AppError::Internal(format!("Failed to hash password: {}", e)))?;

        // 4. Persist and return
        let user = self.repository.create(&req, &password_hash).await?;
        tracing::info!("New user registered: {} ({})", user.username, user.id);

        Ok(user)
    }

    /// Authenticate a user by email and password.
    pub async fn login(&self, req: LoginRequest) -> AppResult<User> {
        // 1. Validate input
        req.validate()
            .map_err(|e| AppError::Validation(e.to_string()))?;

        // 2. Find user by email
        let user = self
            .repository
            .find_by_email(&req.email)
            .await?
            .ok_or_else(|| AppError::Unauthorized("Invalid email or password".to_string()))?;

        // 3. Verify password
        let is_valid = bcrypt::verify(&req.password, &user.password_hash)
            .map_err(|e| AppError::Internal(format!("Failed to verify password: {}", e)))?;

        if !is_valid {
            return Err(AppError::Unauthorized("Invalid email or password".to_string()));
        }

        tracing::info!("User logged in: {} ({})", user.username, user.id);
        Ok(user)
    }

    /// Get user profile by ID.
    pub async fn get_user_by_id(&self, user_id: uuid::Uuid) -> AppResult<User> {
        let user = self
            .repository
            .find_by_id(user_id)
            .await?
            .ok_or_else(|| AppError::NotFound(format!("User with id '{}' not found", user_id)))?;

        tracing::info!("User profile retrieved: {} ({})", user.username, user_id);
        Ok(user)
    }

    /// Update user profile information.
    pub async fn update_user(&self, user_id: uuid::Uuid, req: UpdateUserRequest) -> AppResult<User> {
        // 1. Validate input
        req.validate()
            .map_err(|e| AppError::Validation(e.to_string()))?;

        // 2. Check if user exists
        let existing_user = self
            .repository
            .find_by_id(user_id)
            .await?
            .ok_or_else(|| AppError::NotFound(format!("User with id '{}' not found", user_id)))?;

        // 3. Update the user
        let updated_user = self.repository.update(user_id, &req).await?;
        
        tracing::info!("User profile updated: {} ({})", existing_user.username, user_id);
        Ok(updated_user)
    }
}
