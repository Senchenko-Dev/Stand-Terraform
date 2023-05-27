'''
    Progress bar Ansible callback plugin
'''

from __future__ import (absolute_import, division, print_function)
__metaclass__ = type

from ansible import constants as C
from ansible.plugins.callback import CallbackBase
from ansible.utils.color import colorize, hostcolor
from ansible.template import Templar
from ansible.playbook.task_include import TaskInclude
from ansible.playbook.block import Block   
from ansible.playbook.task import Task
from ansible.playbook.helpers import load_list_of_tasks ,load_list_of_blocks, load_list_of_roles

DOCUMENTATION = '''
    callback: proggress_bar
    type: stdout
    short_description: adds progress bar  to the output items (tasks and hosts/task)
    description:
      - A progress bar is displayed for each PLAY 
      - A progress bar is displayed for each main.yml in ROLE
    extends_documentation_fragment:
      - default_callback
    requirements:
      - set as stdout callback in ansible.cfg  (stdout_callback = proggress_bar)
'''

class CallbackModule(CallbackBase):

    '''
    This is the default callback interface, which simply prints messages
    to stdout when new callback events are received.
    '''

    CALLBACK_VERSION = 2.0
    CALLBACK_TYPE = 'stdout'
    CALLBACK_NAME = 'progress_bar'
   
    _task_counter = 1   #counter executing tasks
    _role_total = 0     #common count role in play 
    _task_total = 0     #common count task in playbook
    _host_counter = 1   #counter executing host 
    _host_total = 0     #common host for task
    _role_counter = 0   #counter executing role in play
    _task_in_role = {}  #dict save role and count task in role for play
    _prev_block = None  #save pred parent for task 
    _cur_block = None   #current parent for executing task
    _prev_roles = None  #prev execute role 

    def __init__(self):
        super(CallbackModule, self).__init__()

        self._playbook = ""
        self._play = ""

    def _all_vars(self, host=None, task=None):
        # host and task need to be specified in case 'magic variables' (host vars, group vars, etc)
        # need to be loaded as well
        return self._play.get_variable_manager().get_vars(
            play=self._play,
            host=host,
            task=task
        )

    def v2_playbook_on_start(self, playbook):
        '''
        Run this function for each playbook start and save playbook object
        '''
        self._playbook = playbook

    def v2_playbook_on_play_start(self, play):
        '''
        Run with function on each play
        play -- ansible object for play(more information /usr/lib/python2.7/site-packages/ansible/playbook/role) 
        This function determinate count role in PLAY and count task in role
        '''
        self._task_counter = 0
        self._task_in_role = {}
        self._role_counter = 0
        name = play.get_name().strip()
        if not name:
            msg = u"play"
        else:
            msg = u"PLAY [%s]" % name

        self._play = play
        self._display.banner(msg)
        self._play = play
        self._host_total = len(self._all_vars()['vars']['ansible_play_hosts_all'])
        self._task_total = len(self._play.get_tasks())
	
        self._display.display(str((self._play._ds)))
        roles = self._play.get_roles()

        tasks = self._play.pre_tasks
        # for each role determinate task count in main.yml
        for r in roles:
            #load task from role in list
            task_data = r._load_role_yaml('tasks', main=r._from_files.get('tasks'))
            # for each role read tasks 
            tasks_list = load_list_of_tasks(task_data, play=self._play, role=r, loader=r._loader, variable_manager=r._variable_manager)
            # get task count for each main.yml in role
            task_count = 0
            preview_parent = None
            for tas in tasks_list:
                #if task object is block you need correct determinate all task in block
                if isinstance(tas, Block):
                    # if block without parrent determinate prev_parenr as _uuid
                    if tas._parent is None and preview_parent != tas._uuid:
                        task_count +=1
                        preview_parent = tas._uuid
                    # if block without parrent determinate prev_parenr as _parent
                    elif tas._parent != None and preview_parent != tas._parent:
                        task_count +=1
                        preview_parent = tas._parent      
                # if task is task or include increment counter
                else:
                    task_count +=1
            # save task count for role
            self._task_in_role.update({r:task_count})

    def v2_playbook_on_stats(self, stats):
        '''
        This function formed stats in end execute and display RECAP
        none: this function standart and get from counter_enable plugin
        '''
        self._display.banner("PLAY RECAP")

        hosts = sorted(stats.processed.keys())
        for host in hosts:
            stat = stats.summarize(host)

            self._display.display(u"%s : %s %s %s %s %s %s" % (
                hostcolor(host, stat),
                colorize(u'ok', stat['ok'], C.COLOR_OK),
                colorize(u'changed', stat['changed'], C.COLOR_CHANGED),
                colorize(u'unreachable', stat['unreachable'], C.COLOR_UNREACHABLE),
                colorize(u'failed', stat['failures'], C.COLOR_ERROR),
                colorize(u'rescued', stat['rescued'], C.COLOR_OK),
                colorize(u'ignored', stat['ignored'], C.COLOR_WARN)),
                screen_only=True
            )

            self._display.display(u"%s : %s %s %s %s %s %s" % (
                hostcolor(host, stat, False),
                colorize(u'ok', stat['ok'], None),
                colorize(u'changed', stat['changed'], None),
                colorize(u'unreachable', stat['unreachable'], None),
                colorize(u'failed', stat['failures'], None),
                colorize(u'rescued', stat['rescued'], None),
                colorize(u'ignored', stat['ignored'], None)),
                log_only=True
            )

        self._display.display("", screen_only=True)

        # print custom stats
        if self._plugin_options.get('show_custom_stats', C.SHOW_CUSTOM_STATS) and stats.custom:
            # fallback on constants for inherited plugins missing docs
            self._display.banner("CUSTOM STATS: ")
            # per host
            # TODO: come up with 'pretty format'
            for k in sorted(stats.custom.keys()):
                if k == '_run':
                    continue
                self._display.display('\t%s: %s' % (k, self._dump_results(stats.custom[k], indent=1).replace('\n', '')))

            # print per run custom stats
            if '_run' in stats.custom:
                self._display.display("", screen_only=True)
                self._display.display('\tRUN: %s' % self._dump_results(stats.custom['_run'], indent=1).replace('\n', ''))
            self._display.display("", screen_only=True)

    def _get_parent_object(self,task_parent):
        '''
        This function determinate parent for task
        task_parent -- input params, this first parent for task
        if task parent is None, when parent will be determinate as uuid
        else parent will be recursively determinate for task
        '''
        if task_parent is None:
            #if cur parent not none check parrent type
            #if type is block set parent as uuid 
            #else set parent as _parent
            if self._cur_block is not None:
                if isinstance(self._cur_block,Block):
                    self._cur_block = self._cur_block._parent._uuid 
                    return self._cur_block
                else:   
                    return self._cur_block
            else:
                return None
        else:
            new_parent = task_parent._parent
            #if parent for task is block, then block maybe have parent too
            if isinstance(new_parent, Block):
                #if block parent is none then this last block and
                # need continue without overriding the parent
                if new_parent._parent is None:
                    self._get_parent_object(new_parent._parent)
                #if block not last, but it parent uuid same as last uuid, 
                # then we assume that this block is the last one and
                # without overriding the parent     
                elif str(new_parent._parent._uuid) == str(new_parent._uuid):
                    self._get_parent_object(new_parent._parent)
                # else save cur parent as block and continue
                else:
                    self._cur_block = new_parent
                    self._get_parent_object(new_parent)
            # if parent not none when overide parent
            elif new_parent is not None:
                self._cur_block = new_parent
                self._get_parent_object(new_parent)
            else:
                self._get_parent_object(new_parent)

    def v2_playbook_on_task_start(self, task, is_conditional):
        '''
        Run with function on each role 
        This function determinate progress bar for each role and increments the counter 
        if the task has a different parent from the previous one.
        '''
        args = ''
        # args can be specified as no_log in several places: in the task or in
        # the argument spec.  We can check whether the task is no_log but the
        # argument spec can't be because that is only run on the targets
        # machine and we haven't run it there yet at this time.
        #
        # So we give people a config option to affect display of the args so
        # that they can secure this if they feel that their stdout is insecure
        # (shoulder surfing, logging stdout straight to a file, etc).
        
        #determinate which role execute now
        if str(task._role) != str(self._prev_roles) and task._role in self._task_in_role.keys():
            
            self._prev_roles = str(task._role)
            self._role_total = self._task_in_role[task._role]
            self._task_counter = 0
            self._role_counter += 1
            self._display.display("ROLE: Start execute %d role from %d" % (self._role_counter, len(self._task_in_role)))
        
        self._get_parent_object(task._parent)

        # determining whether to increase the counter
        if self._cur_block is None:
            if task._parent._parent is None:
                if str(self._prev_block) != str(task._parent._uuid):
                    self._task_counter += 1
                    self._prev_block = str(task._parent._uuid)
            else:
                if str(self._prev_block) != str(task._parent._parent._uuid):
                    self._task_counter += 1
                    self._prev_block = str(task._parent._parent._uuid)

        elif self._cur_block != None and str(self._prev_block) != str(self._cur_block):
            self._task_counter += 1
            self._prev_block = str(self._cur_block)

        if not task.no_log and C.DISPLAY_ARGS_TO_STDOUT:
            args = ', '.join(('%s=%s' % a for a in task.args.items()))
            args = ' %s' % args

        if self._task_total:
                self._display.banner("TASK %d/%d [%s%s]" % (self._task_counter, self._task_total, (str(task)), args))
        else:
            # this check need if two same role execute in playbook
            if str(task._role) == str(self._prev_roles) and task._role in self._task_in_role.keys() and self._task_counter > int(self._role_total):
                self._task_counter = 1
                self._role_counter += 1
                self._display.display("ROLE: Start execute %d role from %d" % (self._role_counter, len(self._task_in_role)))
                self._display.banner("TASK %d/%d [%s%s]" % (self._task_counter, int(self._role_total), (str(task)), args))
            else:
                self._display.banner("TASK %d/%d [%s%s]" % (self._task_counter, int(self._role_total), (str(task)), args))
        # show path executing task (from counter_enable plugin)
        if self._display.verbosity >= 2:
            path = task.get_path()
            if path:
                self._display.display("task path: %s" % path, color=C.COLOR_DEBUG)

        self._host_counter = 0
        self._cur_block = None

    def v2_runner_on_ok(self, result):
        '''
        this function from counter_enable plugin
        need for formed result execute task if status ok
        '''
        self._host_counter += 1

        delegated_vars = result._result.get('_ansible_delegated_vars', None)

        if self._play.strategy == 'free' and self._last_task_banner != result._task._uuid:
            self._print_task_banner(result._task)

        if isinstance(result._task, TaskInclude):
            return
        elif result._result.get('changed', False):
            if delegated_vars:
                msg = "changed: %d/%d [%s -> %s]" % (self._host_counter, self._host_total, result._host.get_name(), delegated_vars['ansible_host'])
            else:
                msg = "changed: %d/%d [%s]" % (self._host_counter, self._host_total, result._host.get_name())
            color = C.COLOR_CHANGED
        else:
            if delegated_vars:
                msg = "ok: %d/%d [%s -> %s]" % (self._host_counter, self._host_total, result._host.get_name(), delegated_vars['ansible_host'])
            else:
                msg = "ok: %d/%d [%s]" % (self._host_counter, self._host_total, result._host.get_name())
            color = C.COLOR_OK

        self._handle_warnings(result._result)

        if result._task.loop and 'results' in result._result:
            self._process_items(result)
        else:
            self._clean_results(result._result, result._task.action)

            if self._run_is_verbose(result):
                msg += " => %s" % (self._dump_results(result._result),)
            self._display.display(msg, color=color)

    def v2_runner_on_failed(self, result, ignore_errors=False):
        '''
        this function from counter_enable plugin
        need for formed result execute task if status failed
        '''
        self._host_counter += 1

        delegated_vars = result._result.get('_ansible_delegated_vars', None)
        self._clean_results(result._result, result._task.action)

        if self._play.strategy == 'free' and self._last_task_banner != result._task._uuid:
            self._print_task_banner(result._task)

        self._handle_exception(result._result)
        self._handle_warnings(result._result)

        if result._task.loop and 'results' in result._result:
            self._process_items(result)

        else:
            if delegated_vars:
                self._display.display("fatal: %d/%d [%s -> %s]: FAILED! => %s" % (self._host_counter, self._host_total,
                                                                                  result._host.get_name(), delegated_vars['ansible_host'],
                                                                                  self._dump_results(result._result)),
                                      color=C.COLOR_ERROR)
            else:
                self._display.display("fatal: %d/%d [%s]: FAILED! => %s" % (self._host_counter, self._host_total,
                                                                            result._host.get_name(), self._dump_results(result._result)),
                                      color=C.COLOR_ERROR)

        if ignore_errors:
            self._display.display("...ignoring", color=C.COLOR_SKIP)

    def v2_runner_on_skipped(self, result):
        '''
        this function from counter_enable plugin
        need for formed result execute task if status skipped
        '''
        self._host_counter += 1

        if self._plugin_options.get('show_skipped_hosts', C.DISPLAY_SKIPPED_HOSTS):  # fallback on constants for inherited plugins missing docs

            self._clean_results(result._result, result._task.action)

            if self._play.strategy == 'free' and self._last_task_banner != result._task._uuid:
                self._print_task_banner(result._task)

            if result._task.loop and 'results' in result._result:
                self._process_items(result)
            else:
                msg = "skipping: %d/%d [%s]" % (self._host_counter, self._host_total, result._host.get_name())
                if self._run_is_verbose(result):
                    msg += " => %s" % self._dump_results(result._result)
                self._display.display(msg, color=C.COLOR_SKIP)

    def v2_runner_on_unreachable(self, result):
        self._host_counter += 1

        if self._play.strategy == 'free' and self._last_task_banner != result._task._uuid:
            self._print_task_banner(result._task)

        delegated_vars = result._result.get('_ansible_delegated_vars', None)
        if delegated_vars:
            self._display.display("fatal: %d/%d [%s -> %s]: UNREACHABLE! => %s" % (self._host_counter, self._host_total,
                                                                                   result._host.get_name(), delegated_vars['ansible_host'],
                                                                                   self._dump_results(result._result)),
                                  color=C.COLOR_UNREACHABLE)
        else:
            self._display.display("fatal: %d/%d [%s]: UNREACHABLE! => %s" % (self._host_counter, self._host_total,
                                                                             result._host.get_name(), self._dump_results(result._result)),
                                  color=C.COLOR_UNREACHABLE)
