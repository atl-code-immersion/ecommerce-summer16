class CartController < ApplicationController

	before_filter :authenticate_user!, except: [:add_to_cart, :view_order]


  def add_to_cart
  	product = Product.find(params[:product_id])
  	if params[:quantity].to_i > product.quantity
  		redirect_to product, notice: "Only #{product.quantity} left in stock! Please revise order."
  	else

      @order = current_order

	  	line_item = @order.line_items.new(product_id: params[:product_id], quantity: params[:quantity])
      @order.save
      session[:order_id] = @order.id

	  	line_item.line_item_total = Product.find(params[:product_id]).price * line_item.quantity
	  
	  	line_item.save

	  	redirect_to :back
	  end
  end

  def view_order
  	@line_items = current_order.line_items
  end

  def checkout
  	line_items = current_order.line_items
  	current_order.update(user_id: current_user.id, subtotal: 0)

    @order = current_order

  	line_items.each do |line_item|
  		@order.subtotal += line_item.line_item_total
  		@order.order_items[line_item.product_id] = line_item.quantity
  	end

  	@order.sales_tax = @order.subtotal * 0.07
  	@order.grand_total = @order.subtotal + @order.sales_tax
  	@order.save

  	line_items.each do |line_item|
  		line_item.product.quantity -= line_item.quantity
  		line_item.product.save
  	end

  	@order.line_items.destroy_all

  end

  def delete_line_item
    LineItem.find(params[:id]).destroy
    redirect_to :back
  end

  def edit_line_item
    x = LineItem.find(params[:id])

    @notice = nil

    if params[:quantity].to_i < x.product.quantity
      x.update(quantity: params[:quantity])
    else
      @notice = "Only #{x.product.quantity} left in stock! Unable to revise order."
    end

    redirect_to :back, notice: @notice
  end

  def order_complete
    @order = Order.find(params[:order_id])
    @amount = (@order.grand_total.to_f.round(2) * 100).to_i

    customer = Stripe::Customer.create(
      :email => current_user.email,
      :card => params[:stripeToken]
    )

    charge = Stripe::Charge.create(
      :customer => customer.id,
      :amount => @amount,
      :description => 'Rails Stripe customer',
      :currency => 'usd'
    )

    rescue Stripe::CardError => e
    flash[:error] = e.message
    redirect_to charges_path
  end

end





