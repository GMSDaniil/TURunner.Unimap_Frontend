import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../common/widgets/button/basic_app_button.dart';
import '../../../common/bloc/button/button_state_cubit.dart';
import '../../../common/bloc/button/button_state.dart';
import '../../../domain/usecases/logout.dart';
import '../../../domain/entities/user.dart';
import '../../home/bloc/user_display_cubit.dart';
import '../../home/bloc/user_display_state.dart';
import '../../home/pages/welcome.dart';
import '../../../service_locator.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => UserDisplayCubit()..displayUser()),
        BlocProvider(create: (_) => ButtonStateCubit()),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: Text('Profile', style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
          automaticallyImplyLeading: false,
          centerTitle: true,
          actions: [
            // IconButton(
            //   icon: const Icon(Icons.settings),
            //   onPressed: () {
            //     // navigate to Settings page
            //   },
            // ),
          ],
        ),
        body: BlocListener<ButtonStateCubit, ButtonState>(
          listener: (context, state) {
            if (state is ButtonSuccessState) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const WelcomePage()),
              );
            }
          },
          child: BlocBuilder<UserDisplayCubit, UserDisplayState>(
            builder: (context, state) {
              if (state is UserLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is UserLoaded) {
                final user = state.userEntity;

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
                      _buildDescription(),
                      const SizedBox(height: 24),
                      _buildLogoutButton(context),
                      const SizedBox(height: 24),
                    ],
                  ),
                );
              }

              // Not logged in or failed to load user
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "You're not logged in",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: 160,
                        height: 36,
                        child: _GradientButton(
                          text: 'Log In',
                          onPressed: () {
                            Navigator.of(context).pushReplacementNamed('/signin');
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: 160,
                        height: 36,
                        child: _GradientButton(
                          text: 'Sign Up',
                          onPressed: () {
                            Navigator.of(context).pushReplacementNamed('/signup');
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
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
                    // Edit Profile Page
                  },
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 7,
            child: ClipOval(
              child: Container(
                padding: const EdgeInsets.all(6),
                color: const Color.fromARGB(255, 218, 99, 99),
                child: const Icon(Icons.edit, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
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
    return BasicAppButton(
      title: 'Logout',
      onPressed: () {
        context.read<ButtonStateCubit>().execute(usecase: sl<LogoutUseCase>());
      },
    );
  }
}

// Place this widget in the same file (outside your ProfilePage class):

class _GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const _GradientButton({
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(8),
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF8E2DE2), Color(0xFFFF7E5F)], // Use your app's gradient colors
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onPressed,
          child: Center(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
