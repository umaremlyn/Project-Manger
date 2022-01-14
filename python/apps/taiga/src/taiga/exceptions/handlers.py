# -*- coding: utf-8 -*-
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Copyright (c) 2021-present Kaleidos Ventures SL

import http

from fastapi.encoders import jsonable_encoder
from fastapi.exceptions import RequestValidationError
from starlette.exceptions import HTTPException
from starlette.requests import Request
from starlette.responses import JSONResponse
from starlette.status import HTTP_422_UNPROCESSABLE_ENTITY
from taiga.exceptions.api import HTTPException as TaigaHTTPException
from taiga.exceptions.api import codes


async def http_exception_handler(request: Request, exc: HTTPException) -> JSONResponse:
    if isinstance(exc, TaigaHTTPException):
        http_exc_code = getattr(exc, "code", codes.EX_UNKNOWN.code)
        http_exc_message = getattr(exc, "message", codes.EX_UNKNOWN.message)
    else:  # Starlette's HTTPException
        http_exc_code = http.HTTPStatus(exc.status_code).phrase.replace(" ", "-").lower()
        http_exc_message = http.HTTPStatus(exc.status_code).description

    http_exc_detail = exc.detail

    content = {
        "error": {
            "code": http_exc_code,
            "detail": http_exc_detail,
            "message": http_exc_message,
        }
    }

    headers = getattr(exc, "headers", None)
    if headers:
        return JSONResponse(status_code=exc.status_code, content=content, headers=headers)
    else:
        return JSONResponse(status_code=exc.status_code, content=content)


async def request_validation_exception_handler(request: Request, exc: RequestValidationError) -> JSONResponse:
    return JSONResponse(
        status_code=HTTP_422_UNPROCESSABLE_ENTITY,
        content={
            "error": {
                "code": codes.EX_VALIDATION_ERROR.code,
                "detail": jsonable_encoder(exc.errors()),
                "message": codes.EX_VALIDATION_ERROR.message,
            }
        },
    )
