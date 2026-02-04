defmodule Wrt.Emails do
  @moduledoc """
  Email composition for the WRT application.

  Handles creating emails for:
  - Round invitations with magic links
  - Verification codes
  - Reminders
  """

  import Swoosh.Email

  alias Wrt.Mailer

  @from_name "Workshop Referral Tool"
  @from_email "noreply@example.com"

  @doc """
  Sends an invitation email to a contact with their magic link.
  """
  def send_invitation(contact, magic_link, org) do
    contact
    |> invitation_email(magic_link, org)
    |> Mailer.deliver()
  end

  @doc """
  Composes an invitation email.
  """
  def invitation_email(contact, magic_link, org) do
    person = contact.person
    round = contact.round

    magic_link_url = build_magic_link_url(org.slug, magic_link.token)

    new()
    |> to({person.name, person.email})
    |> from({@from_name, from_email(org)})
    |> subject("#{org.name} - You're invited to participate")
    |> html_body(invitation_html(person, round, org, magic_link_url))
    |> text_body(invitation_text(person, round, org, magic_link_url))
  end

  @doc """
  Sends a verification code email.
  """
  def send_verification_code(magic_link, org) do
    magic_link
    |> verification_code_email(org)
    |> Mailer.deliver()
  end

  @doc """
  Composes a verification code email.
  """
  def verification_code_email(magic_link, org) do
    person = magic_link.person

    new()
    |> to({person.name, person.email})
    |> from({@from_name, from_email(org)})
    |> subject("#{org.name} - Your verification code")
    |> html_body(verification_code_html(person, magic_link.code, org))
    |> text_body(verification_code_text(person, magic_link.code, org))
  end

  @doc """
  Sends a reminder email to a contact who hasn't responded.
  """
  def send_reminder(contact, magic_link, org) do
    contact
    |> reminder_email(magic_link, org)
    |> Mailer.deliver()
  end

  @doc """
  Composes a reminder email.
  """
  def reminder_email(contact, magic_link, org) do
    person = contact.person
    round = contact.round

    magic_link_url = build_magic_link_url(org.slug, magic_link.token)

    new()
    |> to({person.name, person.email})
    |> from({@from_name, from_email(org)})
    |> subject("#{org.name} - Reminder: Submit your nominations")
    |> html_body(reminder_html(person, round, org, magic_link_url))
    |> text_body(reminder_text(person, round, org, magic_link_url))
  end

  # Private functions

  defp from_email(_org) do
    # In production, this could be customized per org
    @from_email
  end

  defp build_magic_link_url(org_slug, token) do
    base_url = Application.get_env(:wrt, WrtWeb.Endpoint)[:url][:host] || "localhost:4001"
    scheme = if base_url =~ "localhost", do: "http", else: "https"
    "#{scheme}://#{base_url}/org/#{org_slug}/nominate/#{token}"
  end

  # HTML Email Templates

  defp invitation_html(person, round, org, magic_link_url) do
    deadline = Calendar.strftime(round.deadline, "%B %d, %Y")

    """
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background: #4f46e5; color: white; padding: 20px; border-radius: 8px 8px 0 0; }
        .content { background: #f9fafb; padding: 20px; border: 1px solid #e5e7eb; }
        .button { display: inline-block; background: #4f46e5; color: white; padding: 12px 24px; text-decoration: none; border-radius: 6px; margin: 20px 0; }
        .footer { padding: 20px; font-size: 12px; color: #6b7280; }
      </style>
    </head>
    <body>
      <div class="header">
        <h1 style="margin: 0;">#{org.name}</h1>
      </div>
      <div class="content">
        <p>Hello #{person.name},</p>

        <p>You've been invited to participate in #{org.name}'s workshop participant selection process.</p>

        <p>We're looking for your input on who you believe would be valuable participants for an upcoming workshop. Your nominations will help us identify people with diverse perspectives and expertise.</p>

        <p><strong>The deadline to submit your nominations is #{deadline}.</strong></p>

        <p style="text-align: center;">
          <a href="#{magic_link_url}" class="button">Submit Your Nominations</a>
        </p>

        <p>If the button doesn't work, copy and paste this link into your browser:</p>
        <p style="word-break: break-all; font-size: 14px; color: #6b7280;">#{magic_link_url}</p>
      </div>
      <div class="footer">
        <p>This email was sent by #{org.name} using the Workshop Referral Tool.</p>
        <p>If you believe you received this email in error, please ignore it.</p>
      </div>
    </body>
    </html>
    """
  end

  defp invitation_text(person, round, org, magic_link_url) do
    deadline = Calendar.strftime(round.deadline, "%B %d, %Y")

    """
    Hello #{person.name},

    You've been invited to participate in #{org.name}'s workshop participant selection process.

    We're looking for your input on who you believe would be valuable participants for an upcoming workshop. Your nominations will help us identify people with diverse perspectives and expertise.

    The deadline to submit your nominations is #{deadline}.

    Click here to submit your nominations:
    #{magic_link_url}

    ---
    This email was sent by #{org.name} using the Workshop Referral Tool.
    If you believe you received this email in error, please ignore it.
    """
  end

  defp verification_code_html(person, code, org) do
    """
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background: #4f46e5; color: white; padding: 20px; border-radius: 8px 8px 0 0; }
        .content { background: #f9fafb; padding: 20px; border: 1px solid #e5e7eb; }
        .code { font-size: 32px; font-weight: bold; letter-spacing: 8px; text-align: center; background: #e5e7eb; padding: 20px; border-radius: 8px; margin: 20px 0; }
        .footer { padding: 20px; font-size: 12px; color: #6b7280; }
      </style>
    </head>
    <body>
      <div class="header">
        <h1 style="margin: 0;">#{org.name}</h1>
      </div>
      <div class="content">
        <p>Hello #{person.name},</p>

        <p>Here is your verification code:</p>

        <div class="code">#{code}</div>

        <p>Enter this code on the verification page to continue.</p>

        <p><strong>This code expires in 15 minutes.</strong></p>

        <p>If you didn't request this code, you can safely ignore this email.</p>
      </div>
      <div class="footer">
        <p>This email was sent by #{org.name} using the Workshop Referral Tool.</p>
      </div>
    </body>
    </html>
    """
  end

  defp verification_code_text(person, code, org) do
    """
    Hello #{person.name},

    Here is your verification code:

    #{code}

    Enter this code on the verification page to continue.

    This code expires in 15 minutes.

    If you didn't request this code, you can safely ignore this email.

    ---
    This email was sent by #{org.name} using the Workshop Referral Tool.
    """
  end

  defp reminder_html(person, round, org, magic_link_url) do
    deadline = Calendar.strftime(round.deadline, "%B %d, %Y")

    """
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background: #f59e0b; color: white; padding: 20px; border-radius: 8px 8px 0 0; }
        .content { background: #f9fafb; padding: 20px; border: 1px solid #e5e7eb; }
        .button { display: inline-block; background: #f59e0b; color: white; padding: 12px 24px; text-decoration: none; border-radius: 6px; margin: 20px 0; }
        .footer { padding: 20px; font-size: 12px; color: #6b7280; }
      </style>
    </head>
    <body>
      <div class="header">
        <h1 style="margin: 0;">Reminder: #{org.name}</h1>
      </div>
      <div class="content">
        <p>Hello #{person.name},</p>

        <p>This is a friendly reminder that we're still waiting for your nominations for #{org.name}'s workshop participant selection.</p>

        <p><strong>The deadline is #{deadline} - don't miss out!</strong></p>

        <p style="text-align: center;">
          <a href="#{magic_link_url}" class="button">Submit Your Nominations Now</a>
        </p>

        <p>If the button doesn't work, copy and paste this link into your browser:</p>
        <p style="word-break: break-all; font-size: 14px; color: #6b7280;">#{magic_link_url}</p>
      </div>
      <div class="footer">
        <p>This email was sent by #{org.name} using the Workshop Referral Tool.</p>
        <p>If you've already submitted your nominations, please ignore this reminder.</p>
      </div>
    </body>
    </html>
    """
  end

  defp reminder_text(person, round, org, magic_link_url) do
    deadline = Calendar.strftime(round.deadline, "%B %d, %Y")

    """
    Hello #{person.name},

    This is a friendly reminder that we're still waiting for your nominations for #{org.name}'s workshop participant selection.

    The deadline is #{deadline} - don't miss out!

    Click here to submit your nominations:
    #{magic_link_url}

    ---
    This email was sent by #{org.name} using the Workshop Referral Tool.
    If you've already submitted your nominations, please ignore this reminder.
    """
  end
end
