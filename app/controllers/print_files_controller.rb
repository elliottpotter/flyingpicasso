class PrintFilesController < ApplicationController

  def create
    service = PrintFilesService.new(params)
    service.generate
  end

end
