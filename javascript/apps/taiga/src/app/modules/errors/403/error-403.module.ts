/**
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 *
 * Copyright (c) 2021-present Kaleidos Ventures SL
 */

import { CommonModule } from '@angular/common';
import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';
import { TranslocoModule, TRANSLOCO_SCOPE } from '@ngneat/transloco';
import { TuiButtonModule } from '@taiga-ui/core';
import { Error403Component } from './error-403.component';

const routes: Routes = [
  {
    path: '',
    component: Error403Component,
    data: {
      noHeader: true,
    },
  },
];
@NgModule({
  declarations: [Error403Component],
  imports: [
    RouterModule.forChild(routes),
    CommonModule,
    TranslocoModule,
    TuiButtonModule,
  ],
  providers: [
    {
      provide: TRANSLOCO_SCOPE,
      useValue: {
        scope: 'errors_page',
        alias: 'errors_page',
      },
      multi: true,
    },
    {
      provide: TRANSLOCO_SCOPE,
      useValue: {
        scope: 'project_settings',
        alias: 'project_settings',
      },
      multi: true,
    },
  ],
})
export class Error403Module {}
