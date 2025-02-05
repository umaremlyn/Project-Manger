# -*- coding: utf-8 -*-
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Copyright (c) 2023-present Kaleidos INC

from datetime import datetime, timezone
from unittest.mock import MagicMock, patch

import pytest
from taiga.auth.serializers import AccessTokenWithRefreshSerializer
from taiga.conf import settings
from taiga.projects.invitations.services.exceptions import BadInvitationTokenError, InvitationDoesNotExistError
from taiga.tokens import exceptions as tokens_ex
from taiga.users import services
from taiga.users.services import exceptions as ex
from tests.utils import factories as f

##########################################################
# create_user
##########################################################


@pytest.mark.parametrize(
    "project_invitation_token, workspace_invitation_token, accept_project_invitation, accept_workspace_invitation",
    [
        ("eyJ0Token", True, None, None),
        (None, None, "eyJ0Token", True),
    ],
)
async def test_create_user_ok_accept_invitation(
    project_invitation_token,
    accept_project_invitation,
    workspace_invitation_token,
    accept_workspace_invitation,
    tqmanager,
):
    email = "email@email.com"
    username = "email"
    full_name = "Full Name"
    color = 8
    password = "CorrectP4ssword$"
    lang = "es-ES"
    user = f.build_user(id=1, email=email, username=username, full_name=full_name, color=color, lang=lang)

    with (
        patch("taiga.users.services.users_repositories", autospec=True) as fake_users_repo,
        patch("taiga.users.services._generate_verify_user_token", return_value="verify_token") as fake_user_token,
    ):
        fake_users_repo.get_user.return_value = None
        fake_users_repo.create_user.return_value = user

        await services.create_user(
            email=email,
            full_name=full_name,
            color=color,
            password=password,
            accept_project_invitation=accept_project_invitation,
            project_invitation_token=project_invitation_token,
            accept_workspace_invitation=accept_workspace_invitation,
            workspace_invitation_token=workspace_invitation_token,
            lang=lang,
        )

        fake_users_repo.create_user.assert_awaited_once_with(
            email=email, full_name=full_name, color=color, password=password, lang=lang
        )
        assert len(tqmanager.pending_jobs) == 1
        job = tqmanager.pending_jobs[0]
        assert "send_email" in job["task_name"]
        assert job["args"] == {
            "email_name": "sign_up",
            "to": "email@email.com",
            "lang": "es-ES",
            "context": {"verification_token": "verify_token"},
        }

        fake_user_token.assert_awaited_once_with(
            user=user,
            project_invitation_token=project_invitation_token,
            accept_project_invitation=accept_project_invitation,
            workspace_invitation_token=workspace_invitation_token,
            accept_workspace_invitation=accept_workspace_invitation,
        )


async def test_create_user_default_instance_lang(tqmanager):
    email = "email@email.com"
    username = "email"
    full_name = "Full Name"
    password = "CorrectP4ssword$"
    lang = None
    color = 1
    default_instance_lang = settings.LANG
    user = f.build_user(
        id=1, email=email, username=username, full_name=full_name, lang=default_instance_lang, color=color
    )

    accept_project_invitation = True
    project_invitation_token = "eyJ0Token"

    with (
        patch("taiga.users.services.users_repositories", autospec=True) as fake_users_repo,
        patch("taiga.users.services._generate_verify_user_token", return_value="verify_token") as fake_user_token,
    ):
        fake_users_repo.get_user.return_value = None
        fake_users_repo.create_user.return_value = user

        await services.create_user(
            email=email,
            full_name=full_name,
            password=password,
            accept_project_invitation=accept_project_invitation,
            project_invitation_token=project_invitation_token,
            lang=lang,
            color=color,
        )

        fake_users_repo.create_user.assert_awaited_once_with(
            email=email,
            full_name=full_name,
            color=color,
            password=password,
            lang=default_instance_lang,
        )
        assert len(tqmanager.pending_jobs) == 1
        job = tqmanager.pending_jobs[0]
        assert "send_email" in job["task_name"]
        assert job["args"] == {
            "email_name": "sign_up",
            "to": "email@email.com",
            "lang": default_instance_lang,
            "context": {"verification_token": "verify_token"},
        }

        fake_user_token.assert_awaited_once_with(
            user=user,
            project_invitation_token=project_invitation_token,
            accept_project_invitation=accept_project_invitation,
            workspace_invitation_token=None,
            accept_workspace_invitation=True,
        )


async def test_create_user_unverified(tqmanager):
    email = "email@email.com"
    username = "email"
    full_name = "Full Name"
    color = 7
    user = f.build_user(id=1, email=email, username=username, full_name=full_name, is_active=False, color=color)

    with (
        patch("taiga.users.services.users_repositories", autospec=True) as fake_users_repo,
        patch("taiga.users.services._generate_verify_user_token", return_value="verify_token"),
    ):
        fake_users_repo.get_user.return_value = user
        fake_users_repo.update_user.return_value = user
        await services.create_user(email=email, full_name="New Full Name", password="NewCorrectP4ssword&")

        fake_users_repo.update_user.assert_awaited_once()
        assert len(tqmanager.pending_jobs) == 1
        job = tqmanager.pending_jobs[0]
        assert "send_email" in job["task_name"]
        assert job["args"] == {
            "email_name": "sign_up",
            "to": "email@email.com",
            "lang": "en-US",
            "context": {"verification_token": "verify_token"},
        }


async def test_create_user_email_exists():
    with (
        pytest.raises(ex.EmailAlreadyExistsError),
        patch("taiga.users.services.users_repositories", autospec=True) as fake_users_repo,
    ):
        fake_users_repo.get_user.return_value = MagicMock(is_active=True)
        await services.create_user(email="dup.email@email.com", full_name="Full Name", password="CorrectP4ssword&")


##########################################################
# verify_user
##########################################################


async def test_verify_user():
    user = f.build_user(is_active=False)
    now = datetime.now(timezone.utc)

    with (
        patch("taiga.users.services.users_repositories", autospec=True) as fake_users_repo,
        patch("taiga.users.services.aware_utcnow") as fake_aware_utcnow,
    ):
        fake_aware_utcnow.return_value = now
        await services.verify_user(user=user)
        fake_users_repo.update_user.assert_awaited_with(
            user=user,
            values={"is_active": True, "date_verification": now},
        )


##########################################################
# verify_user_from_token
##########################################################


async def test_verify_user_ok_no_invitation_tokens_to_accept():
    user = f.build_user(is_active=False)
    object_data = {"id": 1}
    auth_credentials = AccessTokenWithRefreshSerializer(token="token", refresh="refresh")

    with (
        patch("taiga.users.services.verify_user", autospec=True) as fake_verify_user,
        patch("taiga.users.services.VerifyUserToken", autospec=True) as FakeVerifyUserToken,
        patch("taiga.users.services.users_repositories", autospec=True) as fake_users_repo,
        patch("taiga.users.services.auth_services", autospec=True) as fake_auth_services,
        patch("taiga.users.services.project_invitations_services", autospec=True) as fake_pj_invitations_services,
        patch("taiga.users.services.workspace_invitations_services", autospec=True) as fake_ws_invitations_services,
    ):
        fake_token = FakeVerifyUserToken()
        fake_token.object_data = object_data
        fake_token.get.return_value = None
        fake_auth_services.create_auth_credentials.return_value = auth_credentials
        FakeVerifyUserToken.create.return_value = fake_token
        fake_users_repo.get_user.return_value = user

        info = await services.verify_user_from_token("some_token")

        assert info.auth == auth_credentials
        assert info.project_invitation is None

        fake_token.denylist.assert_awaited_once()
        fake_users_repo.get_user.assert_awaited_once_with(filters=object_data)

        fake_pj_invitations_services.update_user_projects_invitations.assert_awaited_once_with(user=user)
        fake_ws_invitations_services.update_user_workspaces_invitations.assert_awaited_once_with(user=user)

        fake_token.get.assert_any_call("project_invitation_token", None)
        fake_token.get.assert_any_call("workspace_invitation_token", None)
        fake_pj_invitations_services.accept_project_invitation_from_token.assert_not_awaited()
        fake_ws_invitations_services.accept_workspace_invitation_from_token.assert_not_awaited()
        fake_pj_invitations_services.get_project_invitation.assert_not_awaited()
        fake_ws_invitations_services.get_workspace_invitation.assert_not_awaited()

        fake_auth_services.create_auth_credentials.assert_awaited_once_with(user=user)

        fake_verify_user.assert_awaited_once()


@pytest.mark.parametrize(
    "accept_project_invitation",
    [True, False],
)
async def test_verify_user_ok_accepting_or_not_a_project_invitation_token(accept_project_invitation):
    user = f.build_user(is_active=False)
    project_invitation = f.build_project_invitation()
    object_data = {"id": 1}
    project_invitation_token = "invitation_token"
    # accept_project_invitation = True
    auth_credentials = AccessTokenWithRefreshSerializer(token="token", refresh="refresh")

    with (
        patch("taiga.users.services.VerifyUserToken", autospec=True) as FakeVerifyUserToken,
        patch("taiga.users.services.users_repositories", autospec=True) as fake_users_repo,
        patch("taiga.users.services.auth_services", autospec=True) as fake_auth_services,
        patch("taiga.users.services.project_invitations_services", autospec=True) as fake_pj_invitations_services,
        patch("taiga.users.services.workspace_invitations_services", autospec=True) as fake_ws_invitations_services,
    ):
        fake_token = FakeVerifyUserToken()
        fake_token.object_data = object_data
        fake_token.get.side_effect = [project_invitation_token, accept_project_invitation]
        fake_auth_services.create_auth_credentials.return_value = auth_credentials
        FakeVerifyUserToken.create.return_value = fake_token
        fake_pj_invitations_services.get_project_invitation.return_value = project_invitation
        fake_users_repo.get_user.return_value = user

        info = await services.verify_user_from_token("some_token")

        assert info.auth == auth_credentials
        assert info.project_invitation.project.name == project_invitation.project.name

        fake_token.denylist.assert_awaited_once()
        fake_users_repo.get_user.assert_awaited_once_with(filters=object_data)
        fake_pj_invitations_services.update_user_projects_invitations.assert_awaited_once_with(user=user)
        fake_ws_invitations_services.update_user_workspaces_invitations.assert_awaited_once_with(user=user)

        fake_token.get.assert_any_call("project_invitation_token", None)
        fake_token.get.assert_any_call("accept_project_invitation", False)
        fake_pj_invitations_services.get_project_invitation.assert_awaited_once_with(token=project_invitation_token)
        if accept_project_invitation:
            fake_pj_invitations_services.accept_project_invitation_from_token.assert_awaited_once_with(
                token=project_invitation_token, user=user
            )
        else:
            fake_pj_invitations_services.accept_project_invitation_from_token.assert_not_awaited()

        fake_auth_services.create_auth_credentials.assert_awaited_once_with(user=user)


@pytest.mark.parametrize(
    "accept_workspace_invitation",
    [True, False],
)
async def test_verify_user_ok_accepting_or_not_a_workspace_invitation_token(accept_workspace_invitation):
    user = f.build_user(is_active=False)
    workspace_invitation = f.build_workspace_invitation()
    object_data = {"id": 1}
    workspace_invitation_token = "invitation_token"
    auth_credentials = AccessTokenWithRefreshSerializer(token="token", refresh="refresh")

    with (
        patch("taiga.users.services.VerifyUserToken", autospec=True) as FakeVerifyUserToken,
        patch("taiga.users.services.users_repositories", autospec=True) as fake_users_repo,
        patch("taiga.users.services.auth_services", autospec=True) as fake_auth_services,
        patch("taiga.users.services.project_invitations_services", autospec=True) as fake_pj_invitations_services,
        patch("taiga.users.services.workspace_invitations_services", autospec=True) as fake_ws_invitations_services,
    ):
        fake_token = FakeVerifyUserToken()
        fake_token.object_data = object_data
        # First call will be `verify_token.get("project_invitation_token", None)` and should return None
        fake_token.get.side_effect = [None, workspace_invitation_token, accept_workspace_invitation]
        fake_auth_services.create_auth_credentials.return_value = auth_credentials
        FakeVerifyUserToken.create.return_value = fake_token
        fake_ws_invitations_services.get_workspace_invitation.return_value = workspace_invitation
        fake_users_repo.get_user.return_value = user

        info = await services.verify_user_from_token("some_token")

        assert info.auth == auth_credentials
        assert info.workspace_invitation.workspace.name == workspace_invitation.workspace.name

        fake_token.denylist.assert_awaited_once()
        fake_users_repo.get_user.assert_awaited_once_with(filters=object_data)
        fake_pj_invitations_services.update_user_projects_invitations.assert_awaited_once_with(user=user)
        fake_ws_invitations_services.update_user_workspaces_invitations.assert_awaited_once_with(user=user)

        fake_token.get.assert_any_call("project_invitation_token", None)
        fake_token.get.assert_any_call("workspace_invitation_token", None)
        fake_token.get.assert_any_call("accept_workspace_invitation", False)
        fake_ws_invitations_services.get_workspace_invitation.assert_awaited_once_with(token=workspace_invitation_token)
        if accept_workspace_invitation:
            fake_ws_invitations_services.accept_workspace_invitation_from_token.assert_awaited_once_with(
                token=workspace_invitation_token, user=user
            )
        else:
            fake_ws_invitations_services.accept_workspace_invitation_from_token.assert_not_awaited()

        fake_auth_services.create_auth_credentials.assert_awaited_once_with(user=user)


async def test_verify_user_error_with_used_token():
    with (
        patch("taiga.users.services.VerifyUserToken", autospec=True) as FakeVerifyUserToken,
        pytest.raises(ex.UsedVerifyUserTokenError),
    ):
        FakeVerifyUserToken.create.side_effect = tokens_ex.DeniedTokenError

        await services.verify_user_from_token("some_token")


async def test_verify_user_error_with_expired_token():
    with (
        patch("taiga.users.services.VerifyUserToken", autospec=True) as FakeVerifyUserToken,
        pytest.raises(ex.ExpiredVerifyUserTokenError),
    ):
        FakeVerifyUserToken.create.side_effect = tokens_ex.ExpiredTokenError

        await services.verify_user_from_token("some_token")


async def test_verify_user_error_with_invalid_token():
    with (
        patch("taiga.users.services.VerifyUserToken", autospec=True) as FakeVerifyUserToken,
        pytest.raises(ex.BadVerifyUserTokenError),
    ):
        FakeVerifyUserToken.create.side_effect = tokens_ex.TokenError

        await services.verify_user_from_token("some_token")


async def test_verify_user_error_with_invalid_data():
    object_data = {"id": 1}

    with (
        patch("taiga.users.services.VerifyUserToken", autospec=True) as FakeVerifyUserToken,
        patch("taiga.users.services.users_repositories", autospec=True) as fake_users_repo,
        pytest.raises(ex.BadVerifyUserTokenError),
    ):
        fake_token = FakeVerifyUserToken()
        fake_token.object_data = object_data
        FakeVerifyUserToken.create.return_value = fake_token
        fake_users_repo.get_user.return_value = None

        await services.verify_user_from_token("some_token")


@pytest.mark.parametrize(
    "exception",
    [
        BadInvitationTokenError,
        InvitationDoesNotExistError,
    ],
)
async def test_verify_user_error_project_invitation_token(exception):
    user = f.build_user(is_active=False)
    project_invitation = f.build_project_invitation()
    object_data = {"id": 1}
    project_invitation_token = "invitation_token"
    accept_project_invitation = False
    auth_credentials = AccessTokenWithRefreshSerializer(token="token", refresh="refresh")

    with (
        patch("taiga.users.services.VerifyUserToken", autospec=True) as FakeVerifyUserToken,
        patch("taiga.users.services.users_repositories", autospec=True) as fake_users_repo,
        patch("taiga.users.services.project_invitations_services", autospec=True) as fake_invitations_services,
        patch("taiga.users.services.workspace_invitations_services", autospec=True),
        patch("taiga.users.services.auth_services", autospec=True) as fake_auth_services,
    ):
        fake_token = FakeVerifyUserToken()
        fake_token.object_data = object_data
        fake_token.get.side_effect = [project_invitation_token, accept_project_invitation]
        fake_auth_services.create_auth_credentials.return_value = auth_credentials
        FakeVerifyUserToken.create.return_value = fake_token
        fake_invitations_services.get_project_invitation.return_value = project_invitation
        fake_users_repo.get_user.return_value = user

        #  exception when recovering the project invitation
        fake_invitations_services.get_project_invitation.side_effect = exception

        info = await services.verify_user_from_token("some_token")

        assert info.auth == auth_credentials
        # the exception is controlled returning no content (pass)
        assert info.project_invitation is None


##########################################################
# _generate_verify_user_token
##########################################################


@pytest.mark.parametrize(
    "project_invitation_token, accept_project_invitation, expected_keys",
    [
        ("invitation_token", True, ["project_invitation_token", "accept_project_invitation"]),
        ("invitation_token", False, ["project_invitation_token"]),
        (None, False, []),
    ],
)
async def test_generate_verify_ok_accept_project_invitation(
    project_invitation_token, accept_project_invitation, expected_keys
):
    user = f.build_user(is_active=False)
    token = {}

    with patch("taiga.users.services.VerifyUserToken", autospec=True) as FakeVerifyUserToken:
        FakeVerifyUserToken.create_for_object.return_value = token

        verify_user_token_str = await services._generate_verify_user_token(
            user=user,
            project_invitation_token=project_invitation_token,
            accept_project_invitation=accept_project_invitation,
        )

        assert list(token.keys()) == expected_keys
        if "project_invitation_token" in list(token.keys()):
            assert token["project_invitation_token"] == project_invitation_token
        if "accept_project_invitation" in list(token.keys()):
            assert token["accept_project_invitation"] == accept_project_invitation
        assert str(token) == verify_user_token_str


##########################################################
# list_users_as_dict
##########################################################


async def test_list_users_as_dict_with_emails():
    user1 = f.build_user(email="one@taiga.demo", username="one")
    user2 = f.build_user(email="two@taiga.demo", username="two")
    user3 = f.build_user(email="three@taiga.demo", username="three")

    with (patch("taiga.users.services.users_repositories", autospec=True) as fake_users_repo,):
        fake_users_repo.list_users.return_value = [user1, user2, user3]

        emails = [user1.email, user2.email, user3.email]
        users = await services.list_users_emails_as_dict(emails=emails)

        fake_users_repo.list_users.assert_called_once_with(filters={"is_active": True, "emails": emails})
        assert users == {"one@taiga.demo": user1, "two@taiga.demo": user2, "three@taiga.demo": user3}


async def test_list_users_as_dict_with_usernames():
    user1 = f.build_user(email="one@taiga.demo", username="one")
    user2 = f.build_user(email="two@taiga.demo", username="two")
    user3 = f.build_user(email="three@taiga.demo", username="three")

    with (patch("taiga.users.services.users_repositories", autospec=True) as fake_users_repo,):
        fake_users_repo.list_users.return_value = [user1, user2, user3]

        usernames = [user1.username, user2.username, user3.username]
        users = await services.list_users_usernames_as_dict(usernames=usernames)

        fake_users_repo.list_users.assert_called_once_with(filters={"is_active": True, "usernames": usernames})
        assert users == {"one": user1, "two": user2, "three": user3}


#####################################################################
# list_paginated_users_by_text (search users)
#####################################################################


async def test_list_paginated_project_users_by_text_ok():
    with (patch("taiga.users.services.users_repositories", autospec=True) as fake_users_repo,):
        fake_users_repo.get_total_project_users_by_text.return_value = 0
        fake_users_repo.list_project_users_by_text.return_value = []

        pagination, users = await services.list_paginated_users_by_text(
            text="text", project_id="id", offset=9, limit=10
        )

        fake_users_repo.get_total_project_users_by_text.assert_awaited_with(text_search="text", project_id="id")
        fake_users_repo.list_project_users_by_text.assert_awaited_with(
            text_search="text", project_id="id", offset=9, limit=10
        )

        assert users == []


async def test_list_paginated_workspace_users_by_text_ok():
    with (patch("taiga.users.services.users_repositories", autospec=True) as fake_users_repo,):
        fake_users_repo.get_total_workspace_users_by_text.return_value = 0
        fake_users_repo.list_workspace_users_by_text.return_value = []

        pagination, users = await services.list_paginated_users_by_text(
            text="text", workspace_id="id", offset=9, limit=10
        )

        fake_users_repo.get_total_workspace_users_by_text.assert_awaited_with(text_search="text", workspace_id="id")
        fake_users_repo.list_workspace_users_by_text.assert_awaited_with(
            text_search="text", workspace_id="id", offset=9, limit=10
        )

        assert users == []


async def test_list_paginated_default_project_users_by_text_ok():
    with (patch("taiga.users.services.users_repositories", autospec=True) as fake_users_repo,):
        fake_users_repo.get_total_project_users_by_text.return_value = 0
        fake_users_repo.list_project_users_by_text.return_value = []

        pagination, users = await services.list_paginated_users_by_text(text="text", offset=9, limit=10)

        fake_users_repo.get_total_project_users_by_text.assert_awaited_with(text_search="text", project_id=None)
        fake_users_repo.list_project_users_by_text.assert_awaited_with(
            text_search="text", project_id=None, offset=9, limit=10
        )

        assert users == []


##########################################################
# update_user
##########################################################


async def test_update_user_ok(tqmanager):
    user = f.build_user(id=1, full_name="Full Name", lang="es-ES")
    new_full_name = "New Full Name"
    new_lang = "en-US"

    with (patch("taiga.users.services.users_repositories", autospec=True) as fake_users_repo,):
        await services.update_user(
            user=user,
            full_name=new_full_name,
            lang=new_lang,
        )

        fake_users_repo.update_user.assert_awaited_once_with(
            user=user, values={"full_name": new_full_name, "lang": new_lang}
        )


#####################################################################
# delete user
#####################################################################


# TODO


#####################################################################
# reset password
#####################################################################


async def test_password_reset_ok():
    user = f.build_user(is_active=True)
    object_data = {"id": 1}

    with (
        patch("taiga.users.services.users_repositories", autospec=True) as fake_users_repo,
        patch("taiga.users.services.ResetPasswordToken", autospec=True) as FakeResetPasswordToken,
    ):
        fake_token = FakeResetPasswordToken()
        fake_token.object_data = object_data
        FakeResetPasswordToken.create.return_value = fake_token
        fake_users_repo.get_user.return_value = user

        ret = await services._get_user_and_reset_password_token(fake_token)
        fake_users_repo.get_user.assert_awaited_once_with(
            filters={"id": fake_token.object_data["id"], "is_active": True}
        )
        assert ret == (fake_token, user)


@pytest.mark.parametrize(
    "catched_ex, raised_ex",
    [
        (tokens_ex.DeniedTokenError, ex.UsedResetPasswordTokenError),
        (tokens_ex.ExpiredTokenError, ex.ExpiredResetPassswordTokenError),
        (tokens_ex.TokenError, ex.BadResetPasswordTokenError),
    ],
)
async def test_password_reset_error_token(catched_ex, raised_ex):
    with (
        patch("taiga.users.services.ResetPasswordToken", autospec=True) as FakeResetPasswordToken,
        pytest.raises(raised_ex),
    ):
        FakeResetPasswordToken.create.side_effect = catched_ex

        await services._get_user_and_reset_password_token("some_token")


async def test_password_reset_error_no_user_token():
    object_data = {"id": 1}

    with (
        patch("taiga.users.services.users_repositories", autospec=True) as fake_users_repo,
        patch("taiga.users.services.ResetPasswordToken", autospec=True) as FakeResetPasswordToken,
        pytest.raises(ex.BadResetPasswordTokenError),
    ):
        fake_token = FakeResetPasswordToken()
        fake_token.object_data = object_data
        FakeResetPasswordToken.create.return_value = fake_token
        fake_users_repo.get_user.return_value = None

        await services._get_user_and_reset_password_token(fake_token)
        fake_token.denylist.assert_awaited()


async def test_request_reset_password_ok():
    user = f.build_user(is_active=True)

    with (
        patch("taiga.users.services.users_repositories", autospec=True) as fake_users_repo,
        patch("taiga.users.services._send_reset_password_email", return_value=None) as fake_send_reset_password_email,
    ):
        fake_users_repo.get_user.return_value = user

        ret = await services.request_reset_password(user.email)

        fake_users_repo.get_user.assert_awaited_once_with(filters={"username_or_email": user.email, "is_active": True})
        fake_send_reset_password_email.assert_awaited_once_with(user)
        assert ret is None


async def test_request_reset_password_error_user():
    with (
        patch("taiga.users.services.users_repositories", autospec=True) as fake_users_repo,
        patch("taiga.users.services._send_reset_password_email", return_value=None) as fake_send_reset_password_email,
    ):
        fake_users_repo.get_user.return_value = None

        ret = await services.request_reset_password("user@email.com")

        fake_users_repo.get_user.assert_awaited_once()
        fake_send_reset_password_email.assert_not_awaited()
        assert ret is None


async def test_reset_password_send_reset_password_email_ok(tqmanager):
    user = f.build_user()

    with (
        patch(
            "taiga.users.services._generate_reset_password_token", return_value="reset_token"
        ) as fake_generate_reset_password_token,
    ):
        await services._send_reset_password_email(user=user)

        assert len(tqmanager.pending_jobs) == 1
        job = tqmanager.pending_jobs[0]
        assert "send_email" in job["task_name"]
        assert job["args"] == {
            "email_name": "reset_password",
            "to": user.email,
            "lang": "en-US",
            "context": {"reset_password_token": "reset_token"},
        }

        fake_generate_reset_password_token.assert_awaited_once_with(user)


async def test_reset_password_generate_reset_password_token_ok():
    user = f.build_user()

    with (patch("taiga.users.services.ResetPasswordToken", autospec=True) as FakeResetPasswordToken,):
        fake_token = FakeResetPasswordToken()
        FakeResetPasswordToken.create_for_object.return_value = fake_token

        ret = await services._generate_reset_password_token(user=user)
        FakeResetPasswordToken.create_for_object.assert_awaited_once_with(user)
        FakeResetPasswordToken.create_for_object.assert_awaited_once_with(user)
        assert ret == str(fake_token)


async def test_verify_reset_password_token():
    user = f.build_user(is_active=True)

    with (
        patch(
            "taiga.users.services._get_user_and_reset_password_token", autospec=True
        ) as fake_get_user_and_reset_password_token,
        patch("taiga.users.services.ResetPasswordToken", autospec=True) as FakeResetPasswordToken,
    ):
        fake_token = FakeResetPasswordToken()
        fake_get_user_and_reset_password_token.return_value = (fake_token, user)

        ret = await services.verify_reset_password_token(fake_token)

        fake_get_user_and_reset_password_token.assert_awaited_once_with(fake_token)
        assert ret == bool((fake_token, user))


async def test_verify_reset_password_token_ok():
    user = f.build_user(is_active=True)

    with (
        patch(
            "taiga.users.services._get_user_and_reset_password_token", autospec=True
        ) as fake_get_user_and_reset_password_token,
        patch("taiga.users.services.ResetPasswordToken", autospec=True) as FakeResetPasswordToken,
    ):
        fake_token = FakeResetPasswordToken()
        fake_get_user_and_reset_password_token.return_value = (fake_token, user)

        ret = await services.verify_reset_password_token(fake_token)

        fake_get_user_and_reset_password_token.assert_awaited_once_with(fake_token)
        assert ret == bool((fake_token, user))


async def test_reset_password_ok_with_user():
    user = f.build_user(is_active=True)
    password = "password"

    with (
        patch(
            "taiga.users.services._get_user_and_reset_password_token", autospec=True
        ) as fake_get_user_and_reset_password_token,
        patch("taiga.users.services.users_repositories", autospec=True) as fake_users_repo,
        patch("taiga.users.services.ResetPasswordToken", autospec=True) as FakeResetPasswordToken,
    ):
        fake_token = FakeResetPasswordToken()
        fake_token.denylist.return_value = None
        fake_get_user_and_reset_password_token.return_value = (fake_token, user)
        fake_users_repo.change_password.return_value = None

        ret = await services.reset_password(str(fake_token), password)

        fake_users_repo.change_password.assert_awaited_once_with(user=user, password=password)
        assert ret == user


async def test_reset_password_ok_without_user():
    password = "password"

    with (
        patch(
            "taiga.users.services._get_user_and_reset_password_token", autospec=True
        ) as fake_get_user_and_reset_password_token,
        patch("taiga.users.services.ResetPasswordToken", autospec=True) as FakeResetPasswordToken,
    ):
        fake_token = FakeResetPasswordToken()
        fake_token.denylist.return_value = None
        fake_get_user_and_reset_password_token.return_value = (fake_token, None)

        ret = await services.reset_password(str(fake_token), password)

        assert ret is None


##########################################################
# misc - clean_expired_users
##########################################################


async def test_clean_expired_users():
    with patch("taiga.users.services.users_repositories", autospec=True) as fake_users_repo:
        await services.clean_expired_users()
        fake_users_repo.clean_expired_users.assert_awaited_once()


async def test_list_workspaces_delete_info():
    user = f.build_user(is_active=True)
    other_user = f.build_user(is_active=True)
    # user only ws member with projects
    ws1 = f.build_workspace(created_by=user)
    f.build_project(created_by=user, workspace=ws1)
    f.build_project(created_by=user, workspace=ws1)
    # user only ws member with projects
    ws2 = f.build_workspace(created_by=user)
    f.build_project(created_by=user, workspace=ws2)
    # user only ws member without projects
    f.build_workspace(created_by=user)
    # user not only ws member with projects
    ws4 = f.build_workspace(created_by=user)
    f.build_workspace_membership(user=other_user, workspace=ws4)
    f.build_project(created_by=user, workspace=ws4)
    # user not only ws member without projects
    ws5 = f.build_workspace(created_by=user)
    f.build_workspace_membership(user=other_user, workspace=ws5)

    with patch("taiga.users.services.workspaces_repositories", autospec=True) as fake_workspaces_repo:
        fake_workspaces_repo.list_workspaces.return_value = [ws2, ws1]
        workspaces = await services._list_workspaces_delete_info(user=user)

        fake_workspaces_repo.list_workspaces.assert_called_once_with(
            filters={"workspace_member_id": user.id, "num_members": 1, "has_projects": True},
            prefetch_related=["projects"],
        )
        assert workspaces == [ws2, ws1]


async def test_list_projects_delete_info():
    user = f.build_user(is_active=True)
    other_user = f.build_user(is_active=True)
    ws1 = f.build_workspace(created_by=user)
    # user only pj admin but only pj member and only ws member
    f.build_project(created_by=user, workspace=ws1)
    # user only pj admin and not only pj member but only ws member
    pj2_ws1 = f.build_project(created_by=user, workspace=ws1)
    f.build_project_membership(user=other_user, project=pj2_ws1)
    ws2 = f.build_workspace(created_by=user)
    f.build_workspace_membership(user=other_user, workspace=ws2)
    # user not only ws member but not only pj admin
    pj1_ws2 = f.build_project(created_by=user, workspace=ws2)
    admin_role = f.build_project_role(project=pj1_ws2, is_admin=True)
    f.build_project_membership(user=other_user, project=pj1_ws2, role=admin_role)
    ws3 = f.build_workspace(created_by=other_user)
    # user not ws member and only pj admin
    pj1_ws3 = f.build_project(created_by=user, workspace=ws3)
    f.build_project_membership(user=other_user, project=pj1_ws3)
    ws4 = f.build_workspace(created_by=user)
    f.build_workspace_membership(user=other_user, workspace=ws4)
    # user not only ws member and only pj admin
    pj1_ws4 = f.build_project(created_by=user, workspace=ws4)
    admin_role = f.build_project_role(project=pj1_ws4, is_admin=True)
    f.build_project_membership(user=other_user, project=pj1_ws4, role=admin_role)

    with (
        patch("taiga.users.services.workspaces_repositories", autospec=True) as fake_workspaces_repo,
        patch("taiga.users.services.projects_repositories", autospec=True) as fake_projects_repo,
    ):
        fake_projects_repo.list_projects.return_value = [pj1_ws4, pj1_ws3]
        projects = await services._list_projects_delete_info(user=user, ws_list=[ws2, ws1])

        fake_workspaces_repo.list_workspace_projects.assert_awaited()
        fake_projects_repo.list_projects.assert_called_once_with(
            filters={"project_member_id": user.id, "is_admin": True, "num_admins": 1, "is_onewoman_project": False},
            select_related=["workspace"],
        )
        assert projects == [pj1_ws4, pj1_ws3]
