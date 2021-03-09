/**
 * Copyright (c) 2014-2021 Taiga Agile LLC
 *
 * This source code is licensed under the terms of the
 * GNU Affero General Public License found in the LICENSE file in
 * the root directory of this source tree.
 */

import { createAction, props } from '@ngrx/store';
import { AppState } from './app.reducer';

export const unexpectedError = createAction(
  '[App] Unexpected error',
  props<{error: AppState['unexpectedError']}>()
);

export const wsMessage = createAction(
  '[App] ws message',
  props<{data: unknown}>()
);
