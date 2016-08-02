class CartController < ApplicationController

	before_filter :authenticate_user!, except: [:add_to_cart, :view_order]


  def add_to_cart

  	product = Product.find(params[:product_id])
  	if params[:quantity].to_i > product.quantity
  		redirect_to product, notice: "Only #{product.quantity} left in stock! Please revise order."
  	else

	  	line_item = LineItem.create(product_id: params[:product_id], quantity: params[:quantity])

	  	line_item.line_item_total = Product.find(params[:product_id]).price * line_item.quantity
	  
	  	line_item.save

	  	redirect_to :back
	  end
  end

  def view_order
  	@line_items = LineItem.order(:created_at)
  end

  def checkout
  	line_items = LineItem.all
  	@order = Order.create(user_id: current_user.id, subtotal: 0)

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

  	LineItem.destroy_all

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

end





