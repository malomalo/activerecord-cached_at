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
      assert_queries(3) {
        EmailMessage.create(emails: [email])
      }
    end

    assert_in_memory_and_persisted(email, :email_messages_cached_at, time)
  end

  test "::update" do
    email = Email.create
    message = EmailMessage.create(emails: [email])

    time = Time.now + 60
    travel_to(time) do
      assert_queries(2) do
        message.update(message: 'new name')
      end
    end

    assert_in_memory_and_persisted(email, :email_messages_cached_at, time)
  end

  test "::destroy" do
    email = Email.create
    message = EmailMessage.create(emails: [email])

    time = Time.now + 60
    travel_to(time) do
      assert_queries(3) { message.destroy }
    end
    
    assert_in_memory_and_persisted(email, :email_messages_cached_at, time)
  end

  test "relationship <<" do
    email = Email.create
    message = EmailMessage.create(emails: [])

    time = Time.now + 60
    travel_to(time) do
      assert_queries(2) { message.emails << email }
    end

    assert_in_memory_and_persisted(email, :email_messages_cached_at, time)
  end

  test "relationship = [...]" do
    email = Email.create
    message = EmailMessage.create

    time = Time.now + 60
    travel_to(time) do
      assert_queries(3) { message.emails = [email] }
    end

    assert_in_memory_and_persisted(email, :email_messages_cached_at, time)
  end

  test "inverse_relationship = [...]" do
    email = Email.create
    message = EmailMessage.create

    time = Time.now + 60
    travel_to(time) do
      assert_queries(3) { email.email_messages = [message] }
    end

    assert_in_memory_and_persisted(email, :email_messages_cached_at, time)
  end

  test "relationship model added via = [...]" do
    email1 = Email.create
    email2 = Email.create

    time1 = Time.now
    message = travel_to(time1) { EmailMessage.create(emails: [email1]) }

    time2 = Time.now + 60
    travel_to(time2) do
      assert_queries(2) {
        message.emails = [email1, email2]
      }
    end

    assert_in_memory_and_persisted(email1, :email_messages_cached_at, time1)
    assert_in_memory_and_persisted(email2, :email_messages_cached_at, time2)
  end

  test "inverse_relationship model added via = [...]" do
    message1 = EmailMessage.create
    message2 = EmailMessage.create

    time1 = Time.now
    email = travel_to(time1) { Email.create(email_messages: [message1]) }

    time2 = Time.now + 60
    travel_to(time2) do
      assert_queries(2) { email.email_messages = [message1, message2] }
    end

    assert_in_memory_and_persisted(email, :email_messages_cached_at, time2)
  end

  test "relationship model removed .delete(...)" do
    email1 = Email.create
    email2 = Email.create

    time1 = Time.now
    message = travel_to(time1) { EmailMessage.create(emails: [email1, email2]) }

    time2 = Time.now + 60
    travel_to(time2) {
      assert_queries(2) do
        message.emails.delete(email1)
      end
    }

    assert_in_memory_and_persisted(email1, :email_messages_cached_at, time2)
    assert_in_memory_and_persisted(email2, :email_messages_cached_at, time1)
  end

  test "relationship model removed via = [...]" do
    email1 = Email.create
    email2 = Email.create

    time1 = Time.now
    message = travel_to(time1) { EmailMessage.create(emails: [email1, email2]) }

    time2 = Time.now + 60
    travel_to(time2) {
      assert_queries(2) { message.emails = [email2] }
    }

    assert_in_memory_and_persisted(email1, :email_messages_cached_at, time2)
    assert_in_memory_and_persisted(email2, :email_messages_cached_at, time1)
  end

  test "inverse_relationship model removed via = [...]" do
    message1 = EmailMessage.create
    message2 = EmailMessage.create

    time1 = Time.now
    email = travel_to(time1) { Email.create(email_messages: [message1, message2]) }

    time2 = Time.now + 60
    travel_to(time2) {
      assert_queries(2) { email.email_messages = [message2] }
    }

    assert_in_memory_and_persisted(email, :email_messages_cached_at, time2)
  end

  test "relationship.clear" do
    email = Email.create
    message = EmailMessage.create(emails: [email])

    time = Time.now + 60
    travel_to(time) do
      assert_queries(2) { message.emails.clear }
    end

    assert_in_memory_and_persisted(email, :email_messages_cached_at, time)
  end

end
