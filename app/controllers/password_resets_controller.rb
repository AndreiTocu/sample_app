class PasswordResetsController < ApplicationController
  before_action :get_user, only: [:edit, :update]
  before_action :valid_user, only: [:edit, :update]
  before_action :check_expiration, only: [:edit, :update]

  def create
    @user = User.find_by(email: params[:password_reset][:email].downcase)
    if @user
      @user.create_reset_digest
      @user.send_password_reset_email
      flash[:info] = "Email sent with password reset instructions"
      redirect_to root_url
    else
      flash[:danger] = "Email address not found"
      render 'new'
    end
  end

  def edit
  end

  def new
  end

  def update
    if params[:user][:password].empty?
      @user.errors.add(:password, "can't be empty")
      render 'edit'
    elsif @user.update(user_params)
      log_in @user
      @user.update_attribute(:reset_digest, nil)
      flash[:success] = "Password has been reset"
      redirect_to @user
    else
      render 'edit'
    end
  end

  private

    # Checks expiration for reset token
    def check_expiration
      if @user.password_reset_expired
        flash[:danger] = "Password reset has expired"
        redirect_to new_password_reset_url
      end
    end

    # Before filters
    def get_user
      @user = User.find_by(email: params[:email])
    end

    def user_params
      params.require(:user).permit(:password, :password_confirmation)
    end

    # Confirms a valid user
    def valid_user
      unless (@user && @user.activated? &&
              @user.authenticated?(:reset, params[:id]))
        # Side implementation. Inform the user that,
        # the email is not correct/valid/activated
        flash[:danger] =
        redirect_to root_url
      end
    end
end
