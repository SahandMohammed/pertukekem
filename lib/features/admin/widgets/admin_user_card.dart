import 'package:flutter/material.dart';
import '../model/admin_user_model.dart';

class AdminUserCard extends StatelessWidget {
  final AdminUserModel user;
  final Function(bool) onToggleBlock;

  const AdminUserCard({
    super.key,
    required this.user,
    required this.onToggleBlock,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  backgroundImage:
                      user.profilePicture != null
                          ? NetworkImage(user.profilePicture!)
                          : null,
                  child:
                      user.profilePicture == null
                          ? Text(
                            user.firstName.isNotEmpty
                                ? user.firstName[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                          : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        user.email,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        user.phoneNumber,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 4.0,
                      ),
                      decoration: BoxDecoration(
                        color:
                            user.isStoreOwner
                                ? Colors.blue.shade100
                                : Colors.green.shade100,
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Text(
                        user.userType,
                        style: TextStyle(
                          color:
                              user.isStoreOwner
                                  ? Colors.blue.shade700
                                  : Colors.green.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (user.isBlocked)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 4.0,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Text(
                          'BLOCKED',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  'Joined ${_formatDate(user.createdAt)}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                const Spacer(),
                Row(
                  children: [
                    Icon(
                      user.isEmailVerified ? Icons.email : Icons.email_outlined,
                      size: 16,
                      color: user.isEmailVerified ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      user.isPhoneVerified ? Icons.phone : Icons.phone_outlined,
                      size: 16,
                      color: user.isPhoneVerified ? Colors.green : Colors.grey,
                    ),
                  ],
                ),
              ],
            ),
            if (user.storeName != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.store, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    'Store: ${user.storeName!}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: () => onToggleBlock(!user.isBlocked),
                  icon: Icon(
                    user.isBlocked ? Icons.check : Icons.block,
                    size: 16,
                  ),
                  label: Text(user.isBlocked ? 'Unblock' : 'Block'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: user.isBlocked ? Colors.green : Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} year${(difference.inDays / 365).floor() > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} month${(difference.inDays / 30).floor() > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else {
      return 'Today';
    }
  }
}
