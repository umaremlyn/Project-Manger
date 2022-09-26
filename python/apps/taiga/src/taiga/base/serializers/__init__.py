# -*- coding: utf-8 -*-
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Copyright (c) 2021-present Kaleidos Ventures SL

from typing import TYPE_CHECKING, TypeVar

from humps.main import camelize
from pydantic import BaseModel as _BaseModel

if TYPE_CHECKING:
    Model = TypeVar("Model", bound="BaseModel")


class BaseModel(_BaseModel):
    class Config:
        alias_generator = camelize
        allow_population_by_field_name = True
