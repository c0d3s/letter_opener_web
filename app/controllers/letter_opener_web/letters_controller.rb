require_dependency "letter_opener_web/application_controller"

module LetterOpenerWeb
  class LettersController < ApplicationController
    before_filter :check_style, :only => [:show]
    before_filter :load_letter, :only => [:show, :attachment, :destroy]

    def index
      @letters = Letter.search
    end

    def show
      text = @letter.send("#{params[:style]}_text").
        gsub(/"plain\.html"/, "\"#{LetterOpenerWeb.railtie_routes_url_helpers.letter_path(:id => @letter.id, :style => 'plain')}\"").
        gsub(/"rich\.html"/, "\"#{LetterOpenerWeb.railtie_routes_url_helpers.letter_path(:id => @letter.id, :style => 'rich')}\"")
      render :text => text
    end

    def attachment
      @letter = Letter.find(params[:id])
      filename = "#{params[:file]}.#{params[:format]}"

      if file = @letter.attachments[filename]
        send_file(file, :filename => filename, :disposition => 'inline')
      else
        render :text => 'Attachment not found!', :status => 404
      end
    end

    def clear
      Letter.destroy_all
      redirect_to LetterOpenerWeb.railtie_routes_url_helpers.letters_path
    end

    def destroy
      @letter = Letter.find(params[:id])
      @letter.delete
      redirect_to LetterOpenerWeb.railtie_routes_url_helpers.letters_path
    end

    def send_email
      mailer = params["mailer"].constantize
      method = params["method"].to_sym
      required_args = mailer.send(:new).method(method).parameters.map{|x| x[1] if x[0] == :req}.compact
      binding.pry
      require 'factory_girl_rails'
      require_relative "#{Rails.root}/spec/spec_helper"
      args = required_args.map{|x| FactoryGirl.create(x)}
      mailer.send(method, *args).deliver!
      redirect_to letters_path
    end

    private

    def check_style
      params[:style] = 'rich' unless ['plain', 'rich'].include? params[:style]
    end

    def load_letter
      if params[:id]
        @letter = Letter.find(params[:id])
        render :nothing => true, :status => 404 unless @letter.exists?
      end
    end
  end
end
