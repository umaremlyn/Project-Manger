/**
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 *
 * Copyright (c) 2023-present Kaleidos INC
 */

import { animate, style, transition, trigger } from '@angular/animations';
import { Location } from '@angular/common';
import {
  AfterViewInit,
  ChangeDetectorRef,
  Component,
  OnDestroy,
} from '@angular/core';
import { Router } from '@angular/router';
import { UntilDestroy, untilDestroyed } from '@ngneat/until-destroy';
import { Store } from '@ngrx/store';
import { RxState } from '@rx-angular/state';
import { TuiNotification } from '@taiga-ui/core';
import {
  Membership,
  Project,
  Status,
  Story,
  StoryAssignEvent,
  StoryDetail,
  User,
  UserComment,
  Workflow,
  WorkspaceMembership,
} from '@taiga/data';
import { distinctUntilChanged, filter, merge } from 'rxjs';
import {
  selectCurrentProject,
  selectShowBannerOnRevoke,
} from '~/app/modules/project/data-access/+state/selectors/project.selectors';
import { AppService } from '~/app/services/app.service';
import { WsService } from '~/app/services/ws';
import { invitationProjectActions } from '~/app/shared/invite-user-modal/data-access/+state/actions/invitation.action';
import { UserStorageService } from '~/app/shared/user-storage/user-storage.service';
import { filterNil } from '~/app/shared/utils/operators';
import {
  newProjectMembers,
  permissionsUpdate,
  projectEventActions,
} from '../data-access/+state/actions/project.actions';
import { setNotificationClosed } from '../feature-overview/data-access/+state/actions/project-overview.actions';

@UntilDestroy()
@Component({
  selector: 'tg-project-feature-shell',
  templateUrl: './project-feature-shell.component.html',
  styleUrls: ['./project-feature-shell.component.css'],
  providers: [RxState],
  animations: [
    trigger('slideInOut', [
      transition(':enter', [
        style({
          blockSize: '0',
          opacity: 0,
        }),
        animate(
          '300ms',
          style({
            blockSize: '110',
            opacity: 1,
          })
        ),
      ]),
      transition(':leave', [
        style({
          blockSize: '110',
          opacity: 1,
        }),
        animate(
          '300ms',
          style({
            blockSize: '0',
            opacity: 0,
          })
        ),
      ]),
    ]),
  ],
})
export class ProjectFeatureShellComponent implements OnDestroy, AfterViewInit {
  public model$ = this.state.select();
  public subscribedProject?: string;
  public animationDisabled = true;

  constructor(
    private store: Store,
    private wsService: WsService,
    private cd: ChangeDetectorRef,
    private state: RxState<{
      project: Project;
      showBannerOnRevoke: boolean;
    }>,
    private userStorageService: UserStorageService,
    private location: Location,
    private router: Router,
    private appService: AppService
  ) {
    this.watchProject();
    this.state.connect(
      'project',
      this.store.select(selectCurrentProject).pipe(filterNil())
    );

    this.state.connect(
      'showBannerOnRevoke',
      this.store.select(selectShowBannerOnRevoke).pipe(filterNil())
    );

    const project$ = this.state
      .select('project')
      .pipe(distinctUntilChanged((prev, curr) => prev.id === curr.id));

    this.state.hold(project$, (project) => {
      const url = window.location.href;
      const newUrl = `project/${project.id}/${project.slug}`;

      if (
        !url.includes('/kanban') &&
        !url.includes('/stories') &&
        !url.includes('/settings') &&
        !url.endsWith(newUrl) // location go when the url doesn't match
      ) {
        this.location.go(newUrl);
      }
      this.subscribedProject = project.id;
      this.unsubscribeFromProjectEvents();
      this.wsService
        .command('subscribe_to_project_events', { project: project.id })
        .subscribe();

      this.store.dispatch(
        setNotificationClosed({
          notificationClosed: !this.showPendingInvitationNotification,
        })
      );
    });
  }

  public get showPendingInvitationNotification() {
    return !this.getRejectedOverviewInvites().includes(this.subscribedProject!);
  }

  public watchProject() {
    this.wsService
      .userEvents<{
        membership: Membership;
        workspace: string;
      }>('projectmemberships.delete')
      .pipe(untilDestroyed(this))
      .subscribe((eventResponse) => {
        if (eventResponse.event.content.membership.project) {
          this.store.dispatch(
            projectEventActions.userLostProjectMembership({
              projectName: eventResponse.event.content.membership.project?.name,
              username: eventResponse.event.content.membership.user.fullName,
              isSelf: true,
            })
          );
        }
      });

    merge(
      this.wsService
        .userEvents<{ membership: Membership }>('projectmemberships.update')
        .pipe(
          filter((data) => {
            return (
              data.event.content.membership.project!.id ===
              this.state.get('project').id
            );
          })
        ),
      this.wsService.projectEvents('projects.permissions.update'),
      this.wsService.projectEvents('projectroles.update')
    )
      .pipe(untilDestroyed(this))
      .subscribe(() => {
        this.store.dispatch(
          permissionsUpdate({ id: this.state.get('project').id })
        );
      });

    this.wsService
      .projectEvents<{ members: Membership[] }>('projectmemberships.create')
      .pipe(untilDestroyed(this))
      .subscribe(() => {
        this.store.dispatch(newProjectMembers());
      });

    this.wsService
      .projectEvents<{ membership: Membership; workspace: string }>(
        'projectmemberships.delete'
      )
      .pipe(untilDestroyed(this))
      .subscribe((eventResponse) => {
        this.store.dispatch(
          projectEventActions.removeMember(eventResponse.event.content)
        );
      });

    this.wsService
      .projectEvents<{ membership: Membership }>('projectmemberships.update')
      .pipe(untilDestroyed(this))
      .subscribe((eventResponse) => {
        this.store.dispatch(
          projectEventActions.updateMember(eventResponse.event.content)
        );
      });

    this.wsService
      .projectEvents<{ story: StoryDetail }>('stories.update')
      .pipe(untilDestroyed(this))
      .subscribe((msg) => {
        this.store.dispatch(
          projectEventActions.updateStory({ story: msg.event.content.story })
        );
      });

    this.wsService
      .projectEvents<StoryAssignEvent>('storiesassignments.create')
      .pipe(untilDestroyed(this))
      .subscribe((eventResponse) => {
        const response = eventResponse.event.content.storyAssignment;
        this.store.dispatch(
          projectEventActions.assignedMemberEvent({
            member: response.user,
            storyRef: response.story.ref,
          })
        );
      });

    this.wsService
      .projectEvents<StoryAssignEvent>('storiesassignments.delete')
      .pipe(untilDestroyed(this))
      .subscribe((eventResponse) => {
        const response = eventResponse.event.content.storyAssignment;
        this.store.dispatch(
          projectEventActions.unassignedMemberEvent({
            member: response.user,
            storyRef: response.story.ref,
          })
        );
      });
    this.wsService
      .projectEvents<{
        project: string;
        workspace: string;
        name: string;
        deleted_by: User;
      }>('projects.delete')
      .pipe(untilDestroyed(this))
      .subscribe((eventResponse) => {
        const project = this.state.get('project');
        if (eventResponse.event.content.project === project.id) {
          this.store.dispatch(
            projectEventActions.projectDeleted({
              projectId: eventResponse.event.content.project,
              workspaceId: eventResponse.event.content.workspace,
              name: eventResponse.event.content.name,
              error: true,
            })
          );
        }
      });

    this.wsService
      .projectEvents<{
        ref: Story['ref'];
        comment: UserComment;
      }>('stories.comments.create')
      .pipe(untilDestroyed(this))
      .subscribe((eventResponse) => {
        this.store.dispatch(
          projectEventActions.createComment({
            storyRef: eventResponse.event.content.ref,
            comment: eventResponse.event.content.comment,
          })
        );
      });

    this.wsService
      .projectEvents<{
        reorder: {
          reorder: { place: 'before' | 'after'; status: Status['id'] };
          statuses: Status['id'][];
          workflow: Pick<Workflow, 'name' | 'slug'>;
        };
      }>('workflowstatuses.reorder')
      .pipe(untilDestroyed(this))
      .subscribe((eventResponse) => {
        this.store.dispatch(
          projectEventActions.statusReorder({
            id: eventResponse.event.content.reorder.statuses[0],
            candidate: {
              position:
                eventResponse.event.content.reorder.reorder.place === 'after'
                  ? 'right'
                  : 'left',
              id: eventResponse.event.content.reorder.reorder.status,
            },
          })
        );
      });

    this.wsService
      .projectEvents<{
        ref: Story['ref'];
        comment: UserComment;
      }>('stories.comments.update')
      .pipe(untilDestroyed(this))
      .subscribe((eventResponse) => {
        this.store.dispatch(
          projectEventActions.editComment({
            storyRef: eventResponse.event.content.ref,
            comment: eventResponse.event.content.comment,
          })
        );
      });

    const userLostPermissions = this.wsService.userEvents<{
      membership: WorkspaceMembership;
    }>('workspacememberships.delete');

    userLostPermissions
      .pipe(
        untilDestroyed(this),
        filter((eventResponse) => {
          return (
            eventResponse.event.content.membership.workspace.id !==
            this.state.get('project').workspace.id
          );
        })
      )
      .subscribe((eventResponse) => {
        if (eventResponse.event.content.membership.workspace) {
          this.store.dispatch(
            projectEventActions.userLostWorkspaceMembership({
              workspaceName:
                eventResponse.event.content.membership.workspace?.name,
            })
          );
        }
      });

    // user lost permissions for the current project
    userLostPermissions
      .pipe(
        untilDestroyed(this),
        filter((eventResponse) => {
          return (
            eventResponse.event.content.membership.workspace.id ===
            this.state.get('project').workspace.id
          );
        })
      )
      .subscribe(() => {
        this.userLoseMembership();
      });
  }

  public userLoseMembership() {
    void this.router.navigate(['/']);
    this.appService.toastNotification({
      message: 'people.remove.no_longer_member',
      paramsMessage: { workspace: this.state.get('project').workspace.name },
      status: TuiNotification.Error,
      scope: 'workspace',
      closeOnNavigation: false,
    });
  }

  public getRejectedOverviewInvites() {
    return (
      this.userStorageService.get<Project['id'][] | undefined>(
        'overview_rejected_invites'
      ) || []
    );
  }

  public ngOnDestroy(): void {
    this.unsubscribeFromProjectEvents();
  }

  public unsubscribeFromProjectEvents() {
    if (this.subscribedProject) {
      this.wsService
        .command('unsubscribe_from_project_events', {
          project: this.subscribedProject,
        })
        .subscribe();
    }
  }

  public ngAfterViewInit() {
    setTimeout(() => {
      this.animationDisabled = false;
      this.cd.detectChanges();
    }, 1000);
  }

  public onNotificationClosed() {
    const rejectedInvites = this.getRejectedOverviewInvites();
    rejectedInvites.push(this.subscribedProject!);
    this.userStorageService.set('overview_rejected_invites', rejectedInvites);
    this.store.dispatch(setNotificationClosed({ notificationClosed: true }));
  }

  public acceptInvitationId() {
    this.store.dispatch(
      invitationProjectActions.acceptInvitationId({
        id: this.state.get('project').id,
        isBanner: true,
      })
    );
  }
}
