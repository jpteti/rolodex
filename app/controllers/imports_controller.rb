class ImportsController < ApplicationController
  def new
  end

  def create
    file = params.expect(import: [ :file ])[:file]
    import = Current.user.address_book.imports.create!(filename: file.original_filename, source: file.read.force_encoding(Encoding::UTF_8))
    ImportJob.perform_later(import)
    redirect_to import
  rescue ActionController::ParameterMissing
    redirect_to new_import_path, alert: "Choose a .vcf file to import."
  end

  def show
    @import = Current.user.address_book.imports.find(params[:id])
  end
end
