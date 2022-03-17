class ConservativeSettingToEnableStatusReference < ActiveRecord::Migration[6.1]
  def up
    User.joins('join settings on users.id = settings.thing_id').where(settings: {thing_type: :User, var: :new_features_policy, value: "--- conservative\n"}).find_each do |user|
      user.settings['enable_status_reference'] = false
    end
  end

  def down
    # nothing to do
  end
end
