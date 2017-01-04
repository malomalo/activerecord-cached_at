require 'test_helper'

class HasManyAndBelongsToManyTest < ActiveSupport::TestCase

  schema do
    create_table "emails", force: :cascade do |t|
      t.integer  "account_id"
      t.datetime 'account_cached_at',      null: false
      t.string   "address",                 limit: 255
      t.datetime "email_messages_cached_at", null: false
    end

    create_table "email_messages", force: :cascade do |t|
      t.string   "message",                 limit: 255
    end

    create_table "email_messages_emails", force: :cascade, id: false do |t|
      t.integer  "email_id",                null: false
      t.integer  "email_message_id",        null: false
    end
    
  end

  class Email < ActiveRecord::Base
    has_and_belongs_to_many :email_messages, inverse_of: :emails
  end

  class EmailMessage < ActiveRecord::Base
    has_and_belongs_to_many :emails, inverse_of: :email_messages, cached_at: true
  end
  
  test "::create" do
    email = Email.create

    time = Time.now + 60
    message = travel_to(time) do
      EmailMessage.create(emails: [email])
    end

    assert_equal time.to_i, email.reload.email_messages_cached_at.to_i
  end

  test "::update" do
    email = Email.create
    message = EmailMessage.create(emails: [email])

    time = Time.now + 60
    travel_to(time) { message.update(message: 'new name') }

    assert_equal time.to_i, email.reload.email_messages_cached_at.to_i
  end

  test "::destroy" do
    email = Email.create
    message = EmailMessage.create(emails: [email])

    time = Time.now + 60
    travel_to(time) { message.destroy }

    assert_equal time.to_i, email.reload.email_messages_cached_at.to_i
  end

  test "relationship <<" do
    email = Email.create
    message = EmailMessage.create(emails: [])

    time = Time.now + 60
    travel_to(time) { message.emails << email }

    assert_equal time.to_i, email.reload.email_messages_cached_at.to_i
  end

  test "relationship = [...]" do
    email = Email.create
    message = EmailMessage.create

    time = Time.now + 60
    travel_to(time) { message.emails = [email] }

    assert_equal time.to_i, email.reload.email_messages_cached_at.to_i
  end

  test "inverse_relationship = [...]" do
    email = Email.create
    message = EmailMessage.create

    time = Time.now + 60
    travel_to(time) { email.email_messages = [message] }

    assert_equal time.to_i, email.reload.email_messages_cached_at.to_i
  end

  test "relationship model added via = [...]" do
    email1 = Email.create
    email2 = Email.create
    message = EmailMessage.create(emails: [email1])

    time = Time.now + 60
    travel_to(time) { message.emails = [email1, email2] }

    assert_equal time.to_i, email2.reload.email_messages_cached_at.to_i
  end

  test "relationship model removed via = [...]" do
    email1 = Email.create
    email2 = Email.create
    message = EmailMessage.create(emails: [email1, email2])

    time = Time.now + 60
    travel_to(time) {
      message.emails = [email2]
    }

    assert_equal time.to_i, email1.reload.email_messages_cached_at.to_i
    # assert_equal time.to_i, email2.reload.email_messages_cached_at.to_i
  end

  test "relationship.clear" do
    email = Email.create
    message = EmailMessage.create(emails: [email])

    time = Time.now + 60
    travel_to(time) { message.emails.clear }

    assert_equal time.to_i, email.reload.email_messages_cached_at.to_i
  end

end
