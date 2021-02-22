class PrintFilesController < ApplicationController

  def create
    service = PrintFilesService.new(params)
    service.generate

    service.print_file_data.each do |print_file_data|
      headers  = { "Content-Type": "application/json" }
      response = Faraday.post('https://hooks.zapier.com/hooks/catch/5011016/opvru9o', print_file_data.to_json, headers)
      puts response.body
    end
  end
  
end
