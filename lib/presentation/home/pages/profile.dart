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
          title: const Text('Profile'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                // navigate to Settings page
              },
            ),
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

              if (state is LoadUserFailure) {
                return Center(child: Text(state.errorMessage));
              }

              return const Center(child: Text('No user data available.'));
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
