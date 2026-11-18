# Native sign-ins no longer name an archive up front; the app picks one after sign-in (ArchiveChoice).
class AllowNativeLoginGrantsWithoutPhotographer < ActiveRecord::Migration[8.1]
  def change
    change_column_null :native_login_grants, :photographer_id, true
  end
end
