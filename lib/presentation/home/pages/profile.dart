import 'package:auth_app/common/providers/user.dart';
import 'package:auth_app/domain/entities/student_schedule.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import '../../../common/widgets/button/basic_app_button.dart';
import '../../../common/bloc/button/button_state_cubit.dart';
import '../../../common/bloc/button/button_state.dart';
import '../../../domain/usecases/logout.dart';
import '../../../domain/entities/user.dart';
import '../../home/bloc/user_display_cubit.dart';
import '../../home/bloc/user_display_state.dart';
import '../../home/pages/welcome.dart';
import '../../../service_locator.dart';

import '../../../common/bloc/auth/auth_state.dart';
import '../../../common/bloc/auth/auth_state_cubit.dart';
import 'package:auth_app/data/models/schedule_req_params.dart';
import 'package:auth_app/domain/usecases/get_student_schedule.dart';
import 'package:auth_app/data/models/student_schedule_response.dart';
import 'package:auth_app/presentation/home/pages/student/student_schedule_detail_page.dart';
import 'package:auth_app/domain/usecases/get_study_programs.dart';
import 'package:auth_app/domain/entities/study_program.dart';
import 'package:auth_app/presentation/widgets/searchable_dropdown.dart';

class ProfilePage extends StatefulWidget {
  final void Function(bool)? onSearchFocusChanged;

  const ProfilePage({Key? key, this.onSearchFocusChanged}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  List<StudentLectureEntity> _lectures = [];
  bool _isLoadingSchedule = false;
  String? _scheduleError;
  bool _showScheduleSection = false;
  
  final _semesterController = TextEditingController();
  final _semesterFocusNode = FocusNode();  // ✅ Add FocusNode

  List<StudyProgramEntity> _studyPrograms = [];
  StudyProgramEntity? _selectedStudyProgram;
  bool _isLoadingStudyPrograms = false;

  @override
  void initState() {
    super.initState();
    _semesterController.text = '2';
    _loadStudyPrograms();
    
    // ✅ Add focus listener
    _semesterFocusNode.addListener(() {
      widget.onSearchFocusChanged?.call(_semesterFocusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _semesterController.dispose();
    _semesterFocusNode.dispose();  // ✅ Dispose FocusNode
    super.dispose();
  }

  Future<void> _loadStudyPrograms() async {
    setState(() => _isLoadingStudyPrograms = true);
    
    final result = await sl<GetStudyProgramsUseCase>().call();
    
    result.fold(
      (error) {
        setState(() {
          _studyPrograms = [];
          _isLoadingStudyPrograms = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load study programs: $error'),
              backgroundColor: Colors.red,
              action: SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: _loadStudyPrograms,
              ),
            ),
          );
        }
      },
      (studyPrograms) {
        setState(() {
          _studyPrograms = studyPrograms;
          _isLoadingStudyPrograms = false;
          
          if (_selectedStudyProgram == null && studyPrograms.isNotEmpty) {
            _selectedStudyProgram = studyPrograms.first;
          }
        });
      },
    );
  }

  Future<void> _fetchSchedule() async {
    final semesterText = _semesterController.text.trim();
    
    if (_selectedStudyProgram == null || semesterText.isEmpty) {
      setState(() => _scheduleError = 'Please select a study program and enter semester');
      return;
    }
    
    if (int.tryParse(semesterText) == null) {
      setState(() => _scheduleError = 'Semester must be a number (e.g., 2, 4, 6)');
      return;
    }

    setState(() {
      _isLoadingSchedule = true;
      _scheduleError = null;
    });

    final params = GetStudentScheduleReqParams(
      studyProgram: _selectedStudyProgram!.stupoNumber,
      semester: semesterText,
      filterDates: true,
    );

    final result = await sl<GetStudentScheduleUseCase>().call(param: params);
    
    result.fold(
      (error) => setState(() {
        _scheduleError = error;
        _isLoadingSchedule = false;
      }),
      (scheduleResponse) => setState(() {
        _lectures = scheduleResponse.lectures;
        _isLoadingSchedule = false;
        _showScheduleSection = true;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use UserProvider to check login state. listen: true ensures UI rebuilds on logout.
    final user = Provider.of<UserProvider>(context).user;

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ButtonStateCubit()),
      ],
      child: SafeArea(
        child: Scaffold(
          body: BlocListener<ButtonStateCubit, ButtonState>(
            listener: (context, state) {
              if (state is ButtonSuccessState) {
                // On successful logout, clear the user from the provider
                Provider.of<UserProvider>(context, listen: false).clearUser();
                // Navigate to welcome page
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const WelcomePage()),
                );
              }
            },
          child: user != null
              ? _buildUserView(context, user)
              : _buildGuestView(context),
          ),
        ),
      ),
    );
  }

  Widget _buildUserView(BuildContext context, UserEntity user) {
    // Wrap the user view with the BlocProvider and BlocListener for the logout button
    return BlocProvider(
      create: (_) => UserDisplayCubit()..displayUser(),
      child: BlocListener<UserDisplayCubit, UserDisplayState>(
        listener: (context, state) {
          if (state is UserLoaded) {
            Provider.of<UserProvider>(context, listen: false).setUser(state.userEntity);
          }
        },
        child: Center(
          child: BlocBuilder<UserDisplayCubit, UserDisplayState>(
            builder: (context, state) {
              if(state is UserLoading) {
                return const CircularProgressIndicator();
              } 
              if (state is UserLoaded) {
                return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 32),
                    _buildProfilePicture(context),
                    const SizedBox(height: 24),
                    _buildUsername(user),
                    const SizedBox(height: 8),
                    _buildEmail(user),
                    const SizedBox(height: 16),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            _buildScheduleSection(),
                            const SizedBox(height: 24),
                            _buildLogoutButton(context),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
              }  
              if (state is LoadUserFailure) {
                return Center(child: Text(state.errorMessage));
              }

              return const Center(
                child: Text('No user data available.'),
              );
              
            }
          ),
        ),
      ),
    );
  }

  Widget _buildUsername(UserEntity user) {
    return Text(
      user.username,
      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildEmail(UserEntity user) {
    return Text(
      user.email,
      style: const TextStyle(fontSize: 16, color: Colors.grey),
    );
  }

  Widget _buildDescription() {
    return const Text(
      'Empty Profile Description',
      style: TextStyle(
        fontStyle: FontStyle.italic,
        fontSize: 16,
        color: Colors.black,
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    // Use the context from the BlocProvider to find the ButtonStateCubit
    return BasicAppButton(
      title: 'Logout',
      onPressed: () {
        context.read<ButtonStateCubit>().execute(
          usecase: sl<LogoutUseCase>(),
        );
      },
    );
  }

  // Guest
  Widget _buildGuestView(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 32),
          _buildProfilePicture(context),
          const SizedBox(height: 24),
          const Text(
            'Guest',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('-', style: TextStyle(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 16),
          // _buildDescription(),
          // const SizedBox(height: 24),
          BasicAppButton(
            title: 'Sign In',
            onPressed: () {
              Navigator.of(context).pushNamed('/signin');
            },
            width: screenWidth,
          ),
          const SizedBox(height: 16),
          BasicAppButton(
            title: 'Create Account',
            onPressed: () {
              Navigator.of(context).pushNamed('/signup');
            },
            width: screenWidth,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildProfilePicture(BuildContext context) {
    return Center(
      child: Stack(
        children: [
          ClipOval(
            child: Material(
              color: Colors.transparent,
              child: Ink.image(
                image: const AssetImage('assets/images/person_profile.png'),
                width: 150,
                height: 150,
                fit: BoxFit.cover,
                child: InkWell(
                  onTap: () {
                    // navigate to edit page
                  },
                ),
              ),
            ),
          ),
          // Positioned(
          //   bottom: 0,
          //   right: 7,
          //   child: ClipOval(
          //     child: Container(
          //       padding: const EdgeInsets.all(6),
          //       color: const Color.fromARGB(255, 218, 99, 99),
          //       child: const Icon(Icons.edit, color: Colors.white, size: 20),
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildScheduleSection() {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: const Icon(
            Icons.schedule, 
            color: Color(0xFF9C27B0),
          ),
          title: const Text(
            'Student Schedule',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Study Program',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      SearchableDropdown(
                        items: _studyPrograms,
                        selectedItem: _selectedStudyProgram,
                        onChanged: (studyProgram) {
                          setState(() {
                            _selectedStudyProgram = studyProgram;
                          });
                        },
                        hintText: 'Search study programs...',
                        isLoading: _isLoadingStudyPrograms,
                        onFocusChanged: (focused) {
                          widget.onSearchFocusChanged?.call(focused);
                          
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Current Semester',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: _semesterController,
                        focusNode: _semesterFocusNode,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                        decoration: InputDecoration(
                          hintText: 'e.g., 2, 4, 6',
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          isDense: true,
                          // ✅ Add clear button as suffix icon
                          suffixIcon: _semesterController.text.isNotEmpty
                              ? IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _semesterController.clear();
                                      _scheduleError = null;  // Clear any error when clearing
                                    });
                                  },
                                  icon: Icon(
                                    Icons.clear,
                                    color: Colors.grey[600],
                                    size: 20,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                )
                              : null,
                        ),
                        onChanged: (value) {
                          setState(() {
                            if (_scheduleError != null) {
                              _scheduleError = null;
                            }
                          });
                        },
                        onTap: () {
                          widget.onSearchFocusChanged?.call(true);
                        },
                        onTapOutside: (_) {
                          widget.onSearchFocusChanged?.call(false);
                          FocusScope.of(context).unfocus();
                        },
                        onFieldSubmitted: (_) {
                          widget.onSearchFocusChanged?.call(false);
                          FocusScope.of(context).unfocus();
                        },
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Enter your current semester number (2nd, 4th, 6th semester, etc.)',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoadingSchedule ? null : _fetchSchedule,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4136),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: _isLoadingSchedule
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Load My Schedule',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),
                  _buildScheduleContent(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleContent() {
    if (_scheduleError != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(top: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.red[50]!,
              Colors.pink[50]!,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red[200]!),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red[700]),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _scheduleError!,
                style: TextStyle(color: Colors.red[700]),
              ),
            ),
          ],
        ),
      );
    }

    if (_lectures.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(top: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF9C27B0).withOpacity(0.1), // Purple with transparency
              const Color(0xFFEF4136).withOpacity(0.1), // Red with transparency
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFF9C27B0).withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: const Color(0xFF9C27B0),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Found ${_lectures.length} lectures',
                style: const TextStyle(
                  color: Color(0xFF9C27B0),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF9C27B0), // Purple
                    Color(0xFFEF4136), // Red
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StudentScheduleDetailPage(
                        lectures: _lectures,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text('View All'),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  void _showFullSchedule() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudentScheduleDetailPage(lectures: _lectures),
      ),
    );
  }
}
