use validator::Validate;

use crate::{
    errors::{AppError, AppResult},
    models::user::{CreateUserRequest, User},
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

        // 3. Persist and return
        let user = self.repository.create(&req).await?;
        tracing::info!("New user registered: {} ({})", user.username, user.id);

        Ok(user)
    }
}
