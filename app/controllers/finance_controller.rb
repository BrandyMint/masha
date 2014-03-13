class FinanceController < ApplicationController
  #authority_actions # :index => 'update', :archivate => 'update'
  authorize_actions_for MoneyIncoming

  def index
    @money_incomings = MoneyIncoming.all
    @money_outgoings = MoneyOutgoing.all

    @money_incoming = MoneyIncoming.new
    @money_outgoing = MoneyOutgoing.new
  end
end
