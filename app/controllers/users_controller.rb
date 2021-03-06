class UsersController < ApplicationController
  before_action :set_paper_trail_whodunnit

  before_action :authenticate_user!, :except => [:user_id, :verify, :authenticate, :authenticate_cas, :authenticate_ms_chap, :authenticate_pam, :public_key]

  def index
    @user_search = params[:user_search]
    @users = []
    @users = User.where("name like ?", "%#{@user_search}%").take(20) if @user_search.present?
  end

  def show
    @user = User.where(id: params[:id]).first

    if @user.access_token.blank?
      access_token = AccessToken.new
      access_token.token = ROTP::Base32.random_base32
      access_token.user = @user
      access_token.save!
    end

    @vpns = Vpn.user_vpns @user

    if current_user.admin? || current_user == @user
      @groups = Group.all
      render_404 if @user.blank?

      if @user.present? && ( current_user.admin? || current_user.id == @user.id)
        respond_to do |format|
          format.html { render :show, flash: {token: access_token.try(:token)} }
        end
      end
    end
  end

  def create
  end

  def update
    @user = User.find(params[:id])
    begin
      @user.update(product_name: product_name)
      response_message = "product name updated successfully!!"
    rescue ActionController::ParameterMissing => e
      response_message = "Params are missing"
    end

    form_response(response_message)
  end

  def search
    @users = User.
      where("name LIKE :q OR email LIKE :q", q: "%#{params[:q]}%").
      order("name ASC").
      limit(20)
    unless params[:include_inactive] == 'true'
      @users = @users.where(active: true)
    end
    data = @users.map{ |user| {
      id: user.id,
      name: user.name,
      email: user.email,
      name_email: "#{user.name} - #{user.email}"
    }}
    render json: data
  end

  # GET /users/:id/regenerate_token
  def regenerate_token
    @user = User.find(params[:id])
    @access_token = @user.access_token
    @access_token.token = ROTP::Base32.random_base32
    respond_to do |format|
      if @access_token.save
        format.html { redirect_to user_path(@user.id), notice: 'Token regenerated.', flash: {token: @access_token.token} }
        format.json { render :show, status: :ok, location: @user }
      else
        format.html { redirect_to user_path(@user.id), notice: 'Token failed to regenerate.' }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  private
  def form_response(message)
    respond_to do |format|
      format.html { redirect_to user_path, notice: message }
    end
  end

  def product_name
    params.require(:product_name)
  end
end
